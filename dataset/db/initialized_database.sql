BEGIN TRANSACTION;
CREATE TABLE answer_revisions (
 session_id TEXT NOT NULL, answer_id TEXT NOT NULL, revision_no INTEGER NOT NULL CHECK(revision_no>0),
 version_id TEXT NOT NULL, field_id TEXT NOT NULL, previous_revision INTEGER,
 resolution_status TEXT NOT NULL CHECK(resolution_status IN ('UNASKED','PARTIAL','AMBIGUOUS','UNCERTAIN','REFUSED','DEFERRED','CONFLICT','CONFIRMED')),
 applicability_status TEXT NOT NULL CHECK(applicability_status IN ('APPLICABLE','NOT_APPLICABLE','WAIT_PARENT')),
 value_boolean INTEGER CHECK(value_boolean IN (0,1)), value_number REAL, value_option TEXT, value_text TEXT,
 precision TEXT NOT NULL DEFAULT 'exact' CHECK(precision IN ('exact','approximate','unspecified')),
 change_reason TEXT NOT NULL, actor TEXT NOT NULL, ruleset_version TEXT NOT NULL,
 created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY(session_id,answer_id,revision_no),
 CHECK(previous_revision IS NULL OR previous_revision<revision_no),
 CHECK((value_boolean IS NOT NULL)+(value_number IS NOT NULL)+(value_option IS NOT NULL)+(value_text IS NOT NULL)<=1),
 CHECK(resolution_status!='CONFIRMED' OR (applicability_status='APPLICABLE' AND (value_boolean IS NOT NULL)+(value_number IS NOT NULL)+(value_option IS NOT NULL)+(value_text IS NOT NULL)=1)),
 CHECK(applicability_status='APPLICABLE' OR (value_boolean IS NULL AND value_number IS NULL AND value_option IS NULL AND value_text IS NULL)),
 FOREIGN KEY(session_id,answer_id,version_id,field_id) REFERENCES answers(session_id,answer_id,version_id,field_id),
 FOREIGN KEY(session_id,answer_id,previous_revision) REFERENCES answer_revisions(session_id,answer_id,revision_no),
 FOREIGN KEY(version_id,field_id,value_option) REFERENCES field_options(version_id,field_id,option_code)
);
CREATE TABLE answer_sources (
 session_id TEXT NOT NULL, answer_id TEXT NOT NULL, revision_no INTEGER NOT NULL, fact_id TEXT NOT NULL,
 PRIMARY KEY(session_id,answer_id,revision_no,fact_id),
 FOREIGN KEY(session_id,answer_id,revision_no) REFERENCES answer_revisions(session_id,answer_id,revision_no),
 FOREIGN KEY(session_id,fact_id) REFERENCES extracted_facts(session_id,fact_id)
);
CREATE TABLE answers (
 session_id TEXT NOT NULL, answer_id TEXT NOT NULL, version_id TEXT NOT NULL, field_id TEXT NOT NULL,
 repeat_key TEXT NOT NULL DEFAULT '', current_revision INTEGER,
 PRIMARY KEY(session_id,answer_id), UNIQUE(session_id,field_id,repeat_key),
 UNIQUE(session_id,answer_id,version_id,field_id),
 FOREIGN KEY(session_id,version_id) REFERENCES sessions(session_id,version_id),
 FOREIGN KEY(version_id,field_id) REFERENCES question_fields(version_id,field_id),
 FOREIGN KEY(session_id,answer_id,current_revision) REFERENCES answer_revisions(session_id,answer_id,revision_no) DEFERRABLE INITIALLY DEFERRED
);
CREATE TABLE extracted_facts (
 session_id TEXT NOT NULL, fact_id TEXT NOT NULL, version_id TEXT NOT NULL, field_id TEXT,
 raw_json TEXT NOT NULL CHECK(json_valid(raw_json)), model_version TEXT, extraction_status TEXT NOT NULL,
 PRIMARY KEY(session_id,fact_id),
 FOREIGN KEY(session_id,version_id) REFERENCES sessions(session_id,version_id),
 FOREIGN KEY(version_id,field_id) REFERENCES question_fields(version_id,field_id)
);
CREATE TABLE fact_evidence (
 session_id TEXT NOT NULL, fact_id TEXT NOT NULL, message_id TEXT NOT NULL,
 start_offset INTEGER NOT NULL CHECK(start_offset>=0), end_offset INTEGER NOT NULL CHECK(end_offset>start_offset),
 evidence_text TEXT NOT NULL,
 PRIMARY KEY(session_id,fact_id,message_id,start_offset,end_offset),
 FOREIGN KEY(session_id,fact_id) REFERENCES extracted_facts(session_id,fact_id),
 FOREIGN KEY(session_id,message_id) REFERENCES messages(session_id,message_id)
);
CREATE TABLE field_options (
 version_id TEXT NOT NULL, field_id TEXT NOT NULL, option_code TEXT NOT NULL, label TEXT NOT NULL,
 PRIMARY KEY(version_id,field_id,option_code),
 FOREIGN KEY(version_id,field_id) REFERENCES question_fields(version_id,field_id)
);
INSERT INTO "field_options" VALUES('national_health_2026_v1','Q3.answer','yes','예');
INSERT INTO "field_options" VALUES('national_health_2026_v1','Q3.answer','no','아니요');
INSERT INTO "field_options" VALUES('national_health_2026_v1','Q3.answer','unknown','모름');
INSERT INTO "field_options" VALUES('national_health_2026_v1','Q4_1.status','current','현재 피움');
INSERT INTO "field_options" VALUES('national_health_2026_v1','Q4_1.status','former','과거에는 피웠으나 현재 피우지 않음');
INSERT INTO "field_options" VALUES('national_health_2026_v1','Q5_1.status','current','현재 피움');
INSERT INTO "field_options" VALUES('national_health_2026_v1','Q5_1.status','former','과거에는 피웠으나 현재 피우지 않음');
INSERT INTO "field_options" VALUES('national_health_2026_v1','Q6_1.use_pattern','no','아니요');
INSERT INTO "field_options" VALUES('national_health_2026_v1','Q6_1.use_pattern','days_1_2','월 1-2일');
INSERT INTO "field_options" VALUES('national_health_2026_v1','Q6_1.use_pattern','days_3_9','월 3-9일');
INSERT INTO "field_options" VALUES('national_health_2026_v1','Q6_1.use_pattern','days_10_29','월 10-29일');
INSERT INTO "field_options" VALUES('national_health_2026_v1','Q6_1.use_pattern','daily','매일');
INSERT INTO "field_options" VALUES('national_health_2026_v1','Q7.unit','week','주');
INSERT INTO "field_options" VALUES('national_health_2026_v1','Q7.unit','month','월');
INSERT INTO "field_options" VALUES('national_health_2026_v1','Q7.unit','year','년');
INSERT INTO "field_options" VALUES('national_health_2026_v1','Q7_1.unit','glass','잔');
INSERT INTO "field_options" VALUES('national_health_2026_v1','Q7_1.unit','bottle','병');
INSERT INTO "field_options" VALUES('national_health_2026_v1','Q7_1.unit','can','캔');
INSERT INTO "field_options" VALUES('national_health_2026_v1','Q7_1.unit','cc','cc');
INSERT INTO "field_options" VALUES('national_health_2026_v1','Q7_2.unit','glass','잔');
INSERT INTO "field_options" VALUES('national_health_2026_v1','Q7_2.unit','bottle','병');
INSERT INTO "field_options" VALUES('national_health_2026_v1','Q7_2.unit','can','캔');
INSERT INTO "field_options" VALUES('national_health_2026_v1','Q7_2.unit','cc','cc');
CREATE TABLE finalizations (
 finalization_id TEXT PRIMARY KEY, session_id TEXT NOT NULL REFERENCES sessions(session_id),
 session_revision INTEGER NOT NULL, confirmation_message_id TEXT NOT NULL,
 completion_scope TEXT NOT NULL CHECK(completion_scope IN ('HEALTH_QUESTIONS','FULL_FORM')),
 snapshot_json TEXT NOT NULL CHECK(json_valid(snapshot_json)), created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
 UNIQUE(session_id,session_revision,completion_scope),
 FOREIGN KEY(session_id,confirmation_message_id) REFERENCES messages(session_id,message_id)
);
CREATE TABLE intake_snapshots (
 intake_id TEXT PRIMARY KEY, subject_id TEXT NOT NULL REFERENCES subjects(subject_id),
 name TEXT, protected_identity_ref TEXT, home_phone TEXT, mobile_phone TEXT, address TEXT, email TEXT,
 delivery_methods_json TEXT NOT NULL DEFAULT '[]' CHECK(json_valid(delivery_methods_json)),
 created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, UNIQUE(intake_id,subject_id)
);
CREATE TABLE messages (
 session_id TEXT NOT NULL REFERENCES sessions(session_id), message_id TEXT NOT NULL,
 sequence_no INTEGER NOT NULL, role TEXT NOT NULL CHECK(role IN ('user','assistant','system')),
 content TEXT NOT NULL, request_id TEXT NOT NULL, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY(session_id,message_id), UNIQUE(session_id,sequence_no), UNIQUE(session_id,request_id)
);
CREATE TABLE question_fields (
 version_id TEXT NOT NULL, field_id TEXT NOT NULL, item_id TEXT NOT NULL, field_name TEXT NOT NULL,
 data_type TEXT NOT NULL CHECK(data_type IN ('boolean','integer','number','option','text')),
 unit TEXT, constraints_json TEXT NOT NULL CHECK(json_valid(constraints_json)),
 repeat_keys_json TEXT NOT NULL CHECK(json_valid(repeat_keys_json)), source_locator TEXT NOT NULL,
 PRIMARY KEY(version_id,field_id), UNIQUE(version_id,item_id,field_name),
 FOREIGN KEY(version_id,item_id) REFERENCES question_items(version_id,item_id)
);
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q1.D01.diagnosed','Q1.D01','diagnosed','boolean',NULL,'{}','[""]','PDF p1, question Q1, row 뇌졸중(중풍)');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q1.D01.on_medication','Q1.D01','on_medication','boolean',NULL,'{}','[""]','PDF p1, question Q1, row 뇌졸중(중풍)');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q1.D02.diagnosed','Q1.D02','diagnosed','boolean',NULL,'{}','[""]','PDF p1, question Q1, row 심근경색/협심증');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q1.D02.on_medication','Q1.D02','on_medication','boolean',NULL,'{}','[""]','PDF p1, question Q1, row 심근경색/협심증');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q1.D03.diagnosed','Q1.D03','diagnosed','boolean',NULL,'{}','[""]','PDF p1, question Q1, row 고혈압');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q1.D03.on_medication','Q1.D03','on_medication','boolean',NULL,'{}','[""]','PDF p1, question Q1, row 고혈압');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q1.D04.diagnosed','Q1.D04','diagnosed','boolean',NULL,'{}','[""]','PDF p1, question Q1, row 당뇨병');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q1.D04.on_medication','Q1.D04','on_medication','boolean',NULL,'{}','[""]','PDF p1, question Q1, row 당뇨병');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q1.D05.diagnosed','Q1.D05','diagnosed','boolean',NULL,'{}','[""]','PDF p1, question Q1, row 이상지질혈증');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q1.D05.on_medication','Q1.D05','on_medication','boolean',NULL,'{}','[""]','PDF p1, question Q1, row 이상지질혈증');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q1.D06.diagnosed','Q1.D06','diagnosed','boolean',NULL,'{}','[""]','PDF p1, question Q1, row 폐결핵');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q1.D06.on_medication','Q1.D06','on_medication','boolean',NULL,'{}','[""]','PDF p1, question Q1, row 폐결핵');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q1.D07.diagnosed','Q1.D07','diagnosed','boolean',NULL,'{}','[""]','PDF p1, question Q1, row 우울증');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q1.D07.on_medication','Q1.D07','on_medication','boolean',NULL,'{}','[""]','PDF p1, question Q1, row 우울증');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q1.D08.diagnosed','Q1.D08','diagnosed','boolean',NULL,'{}','[""]','PDF p1, question Q1, row 조기정신증');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q1.D08.on_medication','Q1.D08','on_medication','boolean',NULL,'{}','[""]','PDF p1, question Q1, row 조기정신증');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q1.D09.diagnosed','Q1.D09','diagnosed','boolean',NULL,'{}','[""]','PDF p1, question Q1, row C형간염');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q1.D09.on_medication','Q1.D09','on_medication','boolean',NULL,'{}','[""]','PDF p1, question Q1, row C형간염');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q1.D10.diagnosed','Q1.D10','diagnosed','boolean',NULL,'{}','[""]','PDF p1, question Q1, row 만성폐쇄성폐질환');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q1.D10.on_medication','Q1.D10','on_medication','boolean',NULL,'{}','[""]','PDF p1, question Q1, row 만성폐쇄성폐질환');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q1.D11.diagnosed','Q1.D11','diagnosed','boolean',NULL,'{}','[""]','PDF p1, question Q1, row 기타(암포함)');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q1.D11.on_medication','Q1.D11','on_medication','boolean',NULL,'{}','[""]','PDF p1, question Q1, row 기타(암포함)');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q2.D01.family_history','Q2.D01','family_history','boolean',NULL,'{}','[""]','PDF p1, question Q2, row 뇌졸중(중풍)');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q2.D02.family_history','Q2.D02','family_history','boolean',NULL,'{}','[""]','PDF p1, question Q2, row 심근경색/협심증');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q2.D03.family_history','Q2.D03','family_history','boolean',NULL,'{}','[""]','PDF p1, question Q2, row 고혈압');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q2.D04.family_history','Q2.D04','family_history','boolean',NULL,'{}','[""]','PDF p1, question Q2, row 당뇨병');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q2.D05.family_history','Q2.D05','family_history','boolean',NULL,'{}','[""]','PDF p1, question Q2, row 기타(암포함)');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q3.answer','Q3','answer','option',NULL,'{}','[""]','PDF p1, question Q3');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q4.answer','Q4','answer','boolean',NULL,'{}','[""]','PDF p1, question Q4');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q4_1.status','Q4_1','status','option',NULL,'{}','[""]','PDF p1, question Q4-1');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q4_1.total_years','Q4_1','total_years','integer','년','{"minimum":0}','[""]','PDF p1, question Q4-1');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q4_1.daily_count','Q4_1','daily_count','number','개비','{"minimum":0}','[""]','PDF p1, question Q4-1');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q4_1.years_since_quit','Q4_1','years_since_quit','number','년','{"minimum":0}','[""]','PDF p1, question Q4-1');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q5.answer','Q5','answer','boolean',NULL,'{}','[""]','PDF p1, question Q5');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q5_1.status','Q5_1','status','option',NULL,'{}','[""]','PDF p1, question Q5-1');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q5_1.total_years','Q5_1','total_years','integer','년','{"minimum":0}','[""]','PDF p1, question Q5-1');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q5_1.daily_count','Q5_1','daily_count','number','개비','{"minimum":0}','[""]','PDF p1, question Q5-1');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q5_1.years_since_quit','Q5_1','years_since_quit','number','년','{"minimum":0}','[""]','PDF p1, question Q5-1');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q6.answer','Q6','answer','boolean',NULL,'{}','[""]','PDF p1, question Q6');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q6_1.use_pattern','Q6_1','use_pattern','option',NULL,'{}','[""]','PDF p1, question Q6-1');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q7.does_not_drink','Q7','does_not_drink','boolean',NULL,'{}','[""]','PDF p1, question Q7');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q7.frequency','Q7','frequency','number',NULL,'{"exclusive_minimum":0}','[""]','PDF p1, question Q7');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q7.unit','Q7','unit','option',NULL,'{}','[""]','PDF p1, question Q7');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q7_1.amount','Q7_1','amount','number',NULL,'{"minimum":0}','["soju","beer","spirits","makgeolli","wine"]','PDF p1, question Q7-1');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q7_1.unit','Q7_1','unit','option',NULL,'{}','["soju","beer","spirits","makgeolli","wine"]','PDF p1, question Q7-1');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q7_2.amount','Q7_2','amount','number',NULL,'{"minimum":0}','["soju","beer","spirits","makgeolli","wine"]','PDF p1, question Q7-2');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q7_2.unit','Q7_2','unit','option',NULL,'{}','["soju","beer","spirits","makgeolli","wine"]','PDF p1, question Q7-2');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q8_1.days','Q8_1','days','integer','day/week','{"maximum":7,"minimum":0}','[""]','PDF p1, question Q8-1');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q8_2.duration_minutes','Q8_2','duration_minutes','integer','minute','{"minimum":0}','[""]','PDF p1, question Q8-2');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q9_1.days','Q9_1','days','integer','day/week','{"maximum":7,"minimum":0}','[""]','PDF p1, question Q9-1');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q9_2.duration_minutes','Q9_2','duration_minutes','integer','minute','{"minimum":0}','[""]','PDF p2, question Q9-2');
INSERT INTO "question_fields" VALUES('national_health_2026_v1','Q10.days','Q10','days','integer','day/week','{"maximum":7,"minimum":0}','[""]','PDF p2, question Q10');
CREATE TABLE question_items (
 version_id TEXT NOT NULL REFERENCES questionnaire_versions(version_id), item_id TEXT NOT NULL,
 official_number TEXT NOT NULL, section_name TEXT NOT NULL, question_text TEXT NOT NULL,
 subject_label TEXT, sequence_no INTEGER NOT NULL, reference_period TEXT, instructions TEXT,
 source_page INTEGER NOT NULL CHECK(source_page IN (1,2)), source_locator TEXT NOT NULL,
 PRIMARY KEY(version_id,item_id), UNIQUE(version_id,sequence_no)
);
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q1.D01','Q1','질환력(과거력, 가족력)','다음과 같은 질병으로 진단을 받았거나, 현재 약물 치료 중이십니까?','뇌졸중(중풍)',1,NULL,NULL,1,'PDF p1, question Q1, row 뇌졸중(중풍)');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q1.D02','Q1','질환력(과거력, 가족력)','다음과 같은 질병으로 진단을 받았거나, 현재 약물 치료 중이십니까?','심근경색/협심증',2,NULL,NULL,1,'PDF p1, question Q1, row 심근경색/협심증');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q1.D03','Q1','질환력(과거력, 가족력)','다음과 같은 질병으로 진단을 받았거나, 현재 약물 치료 중이십니까?','고혈압',3,NULL,NULL,1,'PDF p1, question Q1, row 고혈압');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q1.D04','Q1','질환력(과거력, 가족력)','다음과 같은 질병으로 진단을 받았거나, 현재 약물 치료 중이십니까?','당뇨병',4,NULL,NULL,1,'PDF p1, question Q1, row 당뇨병');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q1.D05','Q1','질환력(과거력, 가족력)','다음과 같은 질병으로 진단을 받았거나, 현재 약물 치료 중이십니까?','이상지질혈증',5,NULL,NULL,1,'PDF p1, question Q1, row 이상지질혈증');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q1.D06','Q1','질환력(과거력, 가족력)','다음과 같은 질병으로 진단을 받았거나, 현재 약물 치료 중이십니까?','폐결핵',6,NULL,NULL,1,'PDF p1, question Q1, row 폐결핵');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q1.D07','Q1','질환력(과거력, 가족력)','다음과 같은 질병으로 진단을 받았거나, 현재 약물 치료 중이십니까?','우울증',7,NULL,NULL,1,'PDF p1, question Q1, row 우울증');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q1.D08','Q1','질환력(과거력, 가족력)','다음과 같은 질병으로 진단을 받았거나, 현재 약물 치료 중이십니까?','조기정신증',8,NULL,NULL,1,'PDF p1, question Q1, row 조기정신증');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q1.D09','Q1','질환력(과거력, 가족력)','다음과 같은 질병으로 진단을 받았거나, 현재 약물 치료 중이십니까?','C형간염',9,NULL,NULL,1,'PDF p1, question Q1, row C형간염');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q1.D10','Q1','질환력(과거력, 가족력)','다음과 같은 질병으로 진단을 받았거나, 현재 약물 치료 중이십니까?','만성폐쇄성폐질환',10,NULL,NULL,1,'PDF p1, question Q1, row 만성폐쇄성폐질환');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q1.D11','Q1','질환력(과거력, 가족력)','다음과 같은 질병으로 진단을 받았거나, 현재 약물 치료 중이십니까?','기타(암포함)',11,NULL,NULL,1,'PDF p1, question Q1, row 기타(암포함)');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q2.D01','Q2','질환력(과거력, 가족력)','부모, 형제, 자매 중에 다음 질환을 앓았거나 해당 질환으로 사망한 경우가 있으십니까?','뇌졸중(중풍)',12,NULL,NULL,1,'PDF p1, question Q2, row 뇌졸중(중풍)');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q2.D02','Q2','질환력(과거력, 가족력)','부모, 형제, 자매 중에 다음 질환을 앓았거나 해당 질환으로 사망한 경우가 있으십니까?','심근경색/협심증',13,NULL,NULL,1,'PDF p1, question Q2, row 심근경색/협심증');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q2.D03','Q2','질환력(과거력, 가족력)','부모, 형제, 자매 중에 다음 질환을 앓았거나 해당 질환으로 사망한 경우가 있으십니까?','고혈압',14,NULL,NULL,1,'PDF p1, question Q2, row 고혈압');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q2.D04','Q2','질환력(과거력, 가족력)','부모, 형제, 자매 중에 다음 질환을 앓았거나 해당 질환으로 사망한 경우가 있으십니까?','당뇨병',15,NULL,NULL,1,'PDF p1, question Q2, row 당뇨병');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q2.D05','Q2','질환력(과거력, 가족력)','부모, 형제, 자매 중에 다음 질환을 앓았거나 해당 질환으로 사망한 경우가 있으십니까?','기타(암포함)',16,NULL,NULL,1,'PDF p1, question Q2, row 기타(암포함)');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q3','Q3','질환력(과거력, 가족력)','B형간염 바이러스 보유자입니까?',NULL,17,NULL,NULL,1,'PDF p1, question Q3');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q4','Q4','흡연 및 전자담배','지금까지 평생 총 5갑(100개비) 이상의 일반담배(궐련)를 피운 적이 있습니까?',NULL,18,NULL,NULL,1,'PDF p1, question Q4');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q4_1','Q4-1','흡연 및 전자담배','현재 일반담배(궐련)를 피우십니까?',NULL,19,NULL,NULL,1,'PDF p1, question Q4-1');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q5','Q5','흡연 및 전자담배','지금까지 궐련형 전자담배(가열담배, 예: 아이코스, 글로, 릴 등)를 사용한 적 있습니까?',NULL,20,NULL,NULL,1,'PDF p1, question Q5');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q5_1','Q5-1','흡연 및 전자담배','현재 궐련형 전자담배(가열담배)를 사용하십니까?',NULL,21,NULL,NULL,1,'PDF p1, question Q5-1');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q6','Q6','흡연 및 전자담배','액상형 전자담배를 사용한 경험이 있습니까?',NULL,22,NULL,NULL,1,'PDF p1, question Q6');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q6_1','Q6-1','흡연 및 전자담배','최근 한 달 동안 액상형 전자담배를 사용한 경험이 있습니까?',NULL,23,'최근 한 달',NULL,1,'PDF p1, question Q6-1');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q7','Q7','음주','지난 1년간 술을 마시는 횟수는 어느 정도입니까?',NULL,24,'지난 1년간',NULL,1,'PDF p1, question Q7');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q7_1','Q7-1','음주','술을 마시는 날은 보통 어느 정도 마십니까?',NULL,25,'지난 1년간',NULL,1,'PDF p1, question Q7-1');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q7_2','Q7-2','음주','하루 동안 가장 많이 마셨던 음주량은 어느 정도입니까?',NULL,26,'지난 1년간',NULL,1,'PDF p1, question Q7-2');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q8_1','Q8-1','신체활동(운동)','평소 1주일간, 숨이 많이 차게 만드는 고강도 신체활동을 며칠 하십니까?',NULL,27,'평소 1주일간',NULL,1,'PDF p1, question Q8-1');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q8_2','Q8-2','신체활동(운동)','평소 하루에 숨이 많이 차게 만드는 고강도 신체활동을 몇 시간 하십니까?',NULL,28,'평소 활동일 하루',NULL,1,'PDF p1, question Q8-2');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q9_1','Q9-1','신체활동(운동)','평소 1주일간, 숨이 약간 차게 만드는 중강도 신체활동을 며칠 하십니까?',NULL,29,'평소 1주일간','Q8 응답에 포함한 신체활동은 제외',1,'PDF p1, question Q9-1');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q9_2','Q9-2','신체활동(운동)','평소 하루에 숨이 약간 차게 만드는 중강도 신체활동을 몇 시간 하십니까?',NULL,30,'평소 활동일 하루',NULL,2,'PDF p2, question Q9-2');
INSERT INTO "question_items" VALUES('national_health_2026_v1','Q10','Q10','신체활동(운동)','최근 1주일 동안 팔굽혀펴기, 윗몸일으키기, 아령, 역기, 철봉 등 근력 운동을 한 날은 며칠입니까?',NULL,31,'최근 1주일',NULL,2,'PDF p2, question Q10');
CREATE TABLE questionnaire_rules (
 version_id TEXT NOT NULL REFERENCES questionnaire_versions(version_id), rule_id TEXT NOT NULL,
 kind TEXT NOT NULL CHECK(kind IN ('APPLICABILITY','FIELD_REQUIREMENT','OPERATION_POLICY','COMPLETION')),
 item_id TEXT, field_id TEXT, condition_json TEXT CHECK(condition_json IS NULL OR json_valid(condition_json)),
 origin TEXT NOT NULL CHECK(origin IN ('official_explicit','project_interpretation','operational_policy')),
 status TEXT NOT NULL CHECK(status IN ('ACTIVE_PROTOTYPE','PENDING')),
 description TEXT NOT NULL, source_locator TEXT,
 PRIMARY KEY(version_id,rule_id),
 FOREIGN KEY(version_id,item_id) REFERENCES question_items(version_id,item_id),
 FOREIGN KEY(version_id,field_id) REFERENCES question_fields(version_id,field_id)
);
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q1.D01.diagnosed','FIELD_REQUIREMENT','Q1.D01','Q1.D01.diagnosed','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q1, row 뇌졸중(중풍)');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q1.D01.on_medication','FIELD_REQUIREMENT','Q1.D01','Q1.D01.on_medication','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q1, row 뇌졸중(중풍)');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q1.D02.diagnosed','FIELD_REQUIREMENT','Q1.D02','Q1.D02.diagnosed','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q1, row 심근경색/협심증');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q1.D02.on_medication','FIELD_REQUIREMENT','Q1.D02','Q1.D02.on_medication','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q1, row 심근경색/협심증');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q1.D03.diagnosed','FIELD_REQUIREMENT','Q1.D03','Q1.D03.diagnosed','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q1, row 고혈압');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q1.D03.on_medication','FIELD_REQUIREMENT','Q1.D03','Q1.D03.on_medication','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q1, row 고혈압');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q1.D04.diagnosed','FIELD_REQUIREMENT','Q1.D04','Q1.D04.diagnosed','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q1, row 당뇨병');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q1.D04.on_medication','FIELD_REQUIREMENT','Q1.D04','Q1.D04.on_medication','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q1, row 당뇨병');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q1.D05.diagnosed','FIELD_REQUIREMENT','Q1.D05','Q1.D05.diagnosed','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q1, row 이상지질혈증');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q1.D05.on_medication','FIELD_REQUIREMENT','Q1.D05','Q1.D05.on_medication','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q1, row 이상지질혈증');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q1.D06.diagnosed','FIELD_REQUIREMENT','Q1.D06','Q1.D06.diagnosed','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q1, row 폐결핵');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q1.D06.on_medication','FIELD_REQUIREMENT','Q1.D06','Q1.D06.on_medication','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q1, row 폐결핵');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q1.D07.diagnosed','FIELD_REQUIREMENT','Q1.D07','Q1.D07.diagnosed','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q1, row 우울증');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q1.D07.on_medication','FIELD_REQUIREMENT','Q1.D07','Q1.D07.on_medication','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q1, row 우울증');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q1.D08.diagnosed','FIELD_REQUIREMENT','Q1.D08','Q1.D08.diagnosed','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q1, row 조기정신증');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q1.D08.on_medication','FIELD_REQUIREMENT','Q1.D08','Q1.D08.on_medication','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q1, row 조기정신증');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q1.D09.diagnosed','FIELD_REQUIREMENT','Q1.D09','Q1.D09.diagnosed','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q1, row C형간염');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q1.D09.on_medication','FIELD_REQUIREMENT','Q1.D09','Q1.D09.on_medication','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q1, row C형간염');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q1.D10.diagnosed','FIELD_REQUIREMENT','Q1.D10','Q1.D10.diagnosed','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q1, row 만성폐쇄성폐질환');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q1.D10.on_medication','FIELD_REQUIREMENT','Q1.D10','Q1.D10.on_medication','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q1, row 만성폐쇄성폐질환');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q1.D11.diagnosed','FIELD_REQUIREMENT','Q1.D11','Q1.D11.diagnosed','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q1, row 기타(암포함)');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q1.D11.on_medication','FIELD_REQUIREMENT','Q1.D11','Q1.D11.on_medication','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q1, row 기타(암포함)');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q2.D01.family_history','FIELD_REQUIREMENT','Q2.D01','Q2.D01.family_history','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q2, row 뇌졸중(중풍)');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q2.D02.family_history','FIELD_REQUIREMENT','Q2.D02','Q2.D02.family_history','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q2, row 심근경색/협심증');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q2.D03.family_history','FIELD_REQUIREMENT','Q2.D03','Q2.D03.family_history','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q2, row 고혈압');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q2.D04.family_history','FIELD_REQUIREMENT','Q2.D04','Q2.D04.family_history','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q2, row 당뇨병');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q2.D05.family_history','FIELD_REQUIREMENT','Q2.D05','Q2.D05.family_history','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q2, row 기타(암포함)');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q3.answer','FIELD_REQUIREMENT','Q3','Q3.answer','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q3');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q4.answer','FIELD_REQUIREMENT','Q4','Q4.answer','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q4');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q4_1.status','FIELD_REQUIREMENT','Q4_1','Q4_1.status','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q4-1');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q4_1.total_years','FIELD_REQUIREMENT','Q4_1','Q4_1.total_years','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q4-1');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q4_1.daily_count','FIELD_REQUIREMENT','Q4_1','Q4_1.daily_count','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q4-1');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q4_1.years_since_quit','FIELD_REQUIREMENT','Q4_1','Q4_1.years_since_quit','{"field":"status","item_id":"Q4_1","op":"equals","value":"former"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q4-1');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','applies_Q4_1','APPLICABILITY','Q4_1',NULL,'{"field":"answer","item_id":"Q4","op":"equals","value":true}','official_explicit','ACTIVE_PROTOTYPE','상위 답변 미확인 시 WAIT_PARENT, 일치 시 적용, 불일치 시 비해당','PDF p1, question Q4-1');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q5.answer','FIELD_REQUIREMENT','Q5','Q5.answer','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q5');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q5_1.status','FIELD_REQUIREMENT','Q5_1','Q5_1.status','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q5-1');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q5_1.total_years','FIELD_REQUIREMENT','Q5_1','Q5_1.total_years','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q5-1');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q5_1.daily_count','FIELD_REQUIREMENT','Q5_1','Q5_1.daily_count','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q5-1');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q5_1.years_since_quit','FIELD_REQUIREMENT','Q5_1','Q5_1.years_since_quit','{"field":"status","item_id":"Q5_1","op":"equals","value":"former"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q5-1');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','applies_Q5_1','APPLICABILITY','Q5_1',NULL,'{"field":"answer","item_id":"Q5","op":"equals","value":true}','official_explicit','ACTIVE_PROTOTYPE','상위 답변 미확인 시 WAIT_PARENT, 일치 시 적용, 불일치 시 비해당','PDF p1, question Q5-1');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q6.answer','FIELD_REQUIREMENT','Q6','Q6.answer','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q6');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q6_1.use_pattern','FIELD_REQUIREMENT','Q6_1','Q6_1.use_pattern','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q6-1');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','applies_Q6_1','APPLICABILITY','Q6_1',NULL,'{"field":"answer","item_id":"Q6","op":"equals","value":true}','project_interpretation','ACTIVE_PROTOTYPE','상위 답변 미확인 시 WAIT_PARENT, 일치 시 적용, 불일치 시 비해당','PDF p1, question Q6-1');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q7.does_not_drink','FIELD_REQUIREMENT','Q7','Q7.does_not_drink','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q7');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q7.frequency','FIELD_REQUIREMENT','Q7','Q7.frequency','{"field":"does_not_drink","item_id":"Q7","op":"equals","value":false}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q7');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q7.unit','FIELD_REQUIREMENT','Q7','Q7.unit','{"field":"does_not_drink","item_id":"Q7","op":"equals","value":false}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q7');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q7_1.amount','FIELD_REQUIREMENT','Q7_1','Q7_1.amount','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q7-1');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q7_1.unit','FIELD_REQUIREMENT','Q7_1','Q7_1.unit','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q7-1');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','applies_Q7_1','APPLICABILITY','Q7_1',NULL,'{"field":"does_not_drink","item_id":"Q7","op":"equals","value":false}','project_interpretation','ACTIVE_PROTOTYPE','상위 답변 미확인 시 WAIT_PARENT, 일치 시 적용, 불일치 시 비해당','PDF p1, question Q7-1');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q7_2.amount','FIELD_REQUIREMENT','Q7_2','Q7_2.amount','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q7-2');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q7_2.unit','FIELD_REQUIREMENT','Q7_2','Q7_2.unit','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q7-2');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','applies_Q7_2','APPLICABILITY','Q7_2',NULL,'{"field":"does_not_drink","item_id":"Q7","op":"equals","value":false}','project_interpretation','ACTIVE_PROTOTYPE','상위 답변 미확인 시 WAIT_PARENT, 일치 시 적용, 불일치 시 비해당','PDF p1, question Q7-2');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q8_1.days','FIELD_REQUIREMENT','Q8_1','Q8_1.days','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q8-1');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q8_2.duration_minutes','FIELD_REQUIREMENT','Q8_2','Q8_2.duration_minutes','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q8-2');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q9_1.days','FIELD_REQUIREMENT','Q9_1','Q9_1.days','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p1, question Q9-1');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q9_2.duration_minutes','FIELD_REQUIREMENT','Q9_2','Q9_2.duration_minutes','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p2, question Q9-2');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','required_Q10.days','FIELD_REQUIREMENT','Q10','Q10.days','{"op":"always"}','project_interpretation','ACTIVE_PROTOTYPE','해당 문항이 적용되면 이 조건에서 필요한 필드','PDF p2, question Q10');
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','never_guess','OPERATION_POLICY',NULL,NULL,NULL,'operational_policy','ACTIVE_PROTOTYPE','모름·거부·미응답은 false/0으로 바꾸지 않음',NULL);
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','preserve_period_unit','OPERATION_POLICY',NULL,NULL,NULL,'operational_policy','ACTIVE_PROTOTYPE','질문의 기준 기간과 횟수 단위를 분리하며 임의 환산하지 않음',NULL);
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','raw_range_before_option','OPERATION_POLICY',NULL,NULL,NULL,'operational_policy','ACTIVE_PROTOTYPE','Q6_1 원시 범위 전체가 선택지에 포함될 때만 매핑. 30일만으로 매일 추정 금지',NULL);
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','explicit_correction','OPERATION_POLICY',NULL,NULL,NULL,'operational_policy','ACTIVE_PROTOTYPE','정정 대상·근거 확인 후 새 revision. 미해결 모순은 덮어쓰기 금지',NULL);
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','recompute_children','OPERATION_POLICY',NULL,NULL,NULL,'operational_policy','ACTIVE_PROTOTYPE','상위 답변 변경 시 하위 적용 여부 재평가. 과거 답변 자동 재확정 금지',NULL);
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','next_unresolved','OPERATION_POLICY',NULL,NULL,NULL,'operational_policy','ACTIVE_PROTOTYPE','확인된 필드는 건너뛰고 미해결 필드를 질문. 마지막 번호만으로 완료 금지',NULL);
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','beverage_list_complete','OPERATION_POLICY',NULL,NULL,NULL,'operational_policy','ACTIVE_PROTOTYPE','술 종류 목록의 완결성을 progress_json에 별도 기록. 미언급 술을 0으로 채우지 않음',NULL);
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','one_unit_per_beverage','OPERATION_POLICY',NULL,NULL,NULL,'operational_policy','ACTIVE_PROTOTYPE','같은 술 종류는 한 단위의 양으로 기록; 혼합 단위는 확인',NULL);
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','review_same_revision','COMPLETION',NULL,NULL,NULL,'operational_policy','ACTIVE_PROTOTYPE','동일 revision의 최종 확인 후 완료. 미해결 항목이 남으면 완료 금지',NULL);
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','intake_required','OPERATION_POLICY',NULL,NULL,NULL,'operational_policy','PENDING','성명·식별정보·연락처 등 필수 접수 필드 범위는 기관 정책 필요',NULL);
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','delivery_cardinality','OPERATION_POLICY',NULL,NULL,NULL,'operational_policy','PENDING','결과 수령방법의 단일/복수 선택 허용 여부 확정 필요',NULL);
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','exercise_zero_duration','OPERATION_POLICY',NULL,NULL,NULL,'operational_policy','PENDING','운동 0일이면 시간 생략/0 처리 여부 확정 필요; 자동 생략하지 않음',NULL);
INSERT INTO "questionnaire_rules" VALUES('national_health_2026_v1','other_beverage_mapping','OPERATION_POLICY',NULL,NULL,NULL,'operational_policy','PENDING','기타 술을 비슷한 종류에 분류하는 기준이 필요. 모델 임의 분류 금지',NULL);
CREATE TABLE questionnaire_versions (
 version_id TEXT PRIMARY KEY, title TEXT NOT NULL, form_revision_date TEXT NOT NULL,
 source_path TEXT NOT NULL, source_sha256 TEXT NOT NULL, schema_sha256 TEXT NOT NULL,
 policy_version TEXT NOT NULL, status TEXT NOT NULL CHECK(status IN ('LOCAL_PROTOTYPE','APPROVED','RETIRED'))
);
INSERT INTO "questionnaire_versions" VALUES('national_health_2026_v1','국가 건강검진 문진표','2026-01-01','reference_goals\official_2026_verified.pdf','244f3c84567cacb60796da2aee3745076ae950573dd7c832548cca52c1799441','7d05479ca610cdf056fe7c466714950ce2a28c2bf7e9c9c89665b230f45ba40c','prototype_policy_1','LOCAL_PROTOTYPE');
CREATE TABLE session_events (
 session_id TEXT NOT NULL REFERENCES sessions(session_id), request_id TEXT NOT NULL,
 kind TEXT NOT NULL, payload_sha256 TEXT NOT NULL, result_json TEXT NOT NULL CHECK(json_valid(result_json)),
 created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY(session_id,request_id)
);
CREATE TABLE sessions (
 session_id TEXT PRIMARY KEY, subject_id TEXT NOT NULL REFERENCES subjects(subject_id),
 version_id TEXT NOT NULL REFERENCES questionnaire_versions(version_id), intake_id TEXT,
 status TEXT NOT NULL CHECK(status IN ('IN_PROGRESS','PAUSED','NEEDS_REVIEW','READY_FOR_REVIEW','COMPLETED')),
 revision INTEGER NOT NULL DEFAULT 0 CHECK(revision>=0), progress_json TEXT NOT NULL DEFAULT '{}' CHECK(json_valid(progress_json)),
 created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, UNIQUE(session_id,version_id),
 FOREIGN KEY(intake_id,subject_id) REFERENCES intake_snapshots(intake_id,subject_id)
);
CREATE TABLE subjects (
 subject_id TEXT PRIMARY KEY, external_subject_ref TEXT UNIQUE, is_synthetic INTEGER NOT NULL CHECK(is_synthetic IN (0,1))
);
CREATE VIEW current_answers AS
 SELECT a.repeat_key,r.* FROM answers a JOIN answer_revisions r
 ON r.session_id=a.session_id AND r.answer_id=a.answer_id AND r.revision_no=a.current_revision;
CREATE TRIGGER evidence_is_user_text BEFORE INSERT ON fact_evidence BEGIN
 SELECT CASE WHEN NOT EXISTS(SELECT 1 FROM messages m WHERE m.session_id=NEW.session_id AND m.message_id=NEW.message_id
  AND m.role='user' AND NEW.end_offset<=length(m.content)
  AND substr(m.content,NEW.start_offset+1,NEW.end_offset-NEW.start_offset)=NEW.evidence_text)
 THEN RAISE(ABORT,'evidence_mismatch') END;
END;
CREATE TRIGGER valid_repeat_key BEFORE INSERT ON answers BEGIN
 SELECT CASE WHEN NOT EXISTS(SELECT 1 FROM question_fields f,json_each(f.repeat_keys_json) k
 WHERE f.version_id=NEW.version_id AND f.field_id=NEW.field_id AND k.value=NEW.repeat_key)
 THEN RAISE(ABORT,'invalid_repeat_key') END;
END;
CREATE TRIGGER answer_type BEFORE INSERT ON answer_revisions BEGIN
 SELECT CASE WHEN EXISTS(SELECT 1 FROM question_fields f WHERE f.version_id=NEW.version_id AND f.field_id=NEW.field_id AND
 ((NEW.value_boolean IS NOT NULL AND f.data_type!='boolean') OR (NEW.value_number IS NOT NULL AND f.data_type NOT IN ('number','integer'))
 OR (NEW.value_option IS NOT NULL AND f.data_type!='option') OR (NEW.value_text IS NOT NULL AND f.data_type!='text')
 OR (f.data_type='integer' AND NEW.value_number!=cast(NEW.value_number AS INTEGER))
 OR (NEW.value_number<json_extract(f.constraints_json,'$.minimum'))
 OR (NEW.value_number>json_extract(f.constraints_json,'$.maximum'))
 OR (NEW.value_number<=json_extract(f.constraints_json,'$.exclusive_minimum'))))
 THEN RAISE(ABORT,'invalid_answer_type_or_range') END;
END;
CREATE TRIGGER answer_history_no_update BEFORE UPDATE ON answer_revisions BEGIN SELECT RAISE(ABORT,'immutable_answer_history'); END;
CREATE TRIGGER answer_history_no_delete BEFORE DELETE ON answer_revisions BEGIN SELECT RAISE(ABORT,'immutable_answer_history'); END;
CREATE TRIGGER finalization_no_update BEFORE UPDATE ON finalizations BEGIN SELECT RAISE(ABORT,'immutable_finalization'); END;
CREATE TRIGGER finalization_no_delete BEFORE DELETE ON finalizations BEGIN SELECT RAISE(ABORT,'immutable_finalization'); END;
CREATE TRIGGER finalization_revision BEFORE INSERT ON finalizations BEGIN
 SELECT CASE WHEN NOT EXISTS(SELECT 1 FROM sessions s JOIN messages m ON m.session_id=s.session_id
 WHERE s.session_id=NEW.session_id AND s.revision=NEW.session_revision AND s.status='READY_FOR_REVIEW'
 AND m.message_id=NEW.confirmation_message_id AND m.role='user') THEN RAISE(ABORT,'invalid_final_confirmation') END;
END;
COMMIT;
