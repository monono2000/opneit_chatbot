-- Local SQLite prototype. Every connection MUST enable foreign_keys.
PRAGMA foreign_keys = ON;
CREATE TABLE IF NOT EXISTS questionnaire_versions (
 version_id TEXT PRIMARY KEY, title TEXT NOT NULL, form_revision_date TEXT NOT NULL,
 source_path TEXT NOT NULL, source_sha256 TEXT NOT NULL, schema_sha256 TEXT NOT NULL,
 policy_version TEXT NOT NULL, status TEXT NOT NULL CHECK(status IN ('LOCAL_PROTOTYPE','APPROVED','RETIRED'))
);
CREATE TABLE IF NOT EXISTS question_items (
 version_id TEXT NOT NULL REFERENCES questionnaire_versions(version_id), item_id TEXT NOT NULL,
 official_number TEXT NOT NULL, section_name TEXT NOT NULL, question_text TEXT NOT NULL,
 subject_label TEXT, sequence_no INTEGER NOT NULL, reference_period TEXT, instructions TEXT,
 source_page INTEGER NOT NULL CHECK(source_page IN (1,2)), source_locator TEXT NOT NULL,
 PRIMARY KEY(version_id,item_id), UNIQUE(version_id,sequence_no)
);
CREATE TABLE IF NOT EXISTS question_fields (
 version_id TEXT NOT NULL, field_id TEXT NOT NULL, item_id TEXT NOT NULL, field_name TEXT NOT NULL,
 data_type TEXT NOT NULL CHECK(data_type IN ('boolean','integer','number','option','text')),
 unit TEXT, constraints_json TEXT NOT NULL CHECK(json_valid(constraints_json)),
 repeat_keys_json TEXT NOT NULL CHECK(json_valid(repeat_keys_json)), source_locator TEXT NOT NULL,
 PRIMARY KEY(version_id,field_id), UNIQUE(version_id,item_id,field_name),
 FOREIGN KEY(version_id,item_id) REFERENCES question_items(version_id,item_id)
);
CREATE TABLE IF NOT EXISTS field_options (
 version_id TEXT NOT NULL, field_id TEXT NOT NULL, option_code TEXT NOT NULL, label TEXT NOT NULL,
 PRIMARY KEY(version_id,field_id,option_code),
 FOREIGN KEY(version_id,field_id) REFERENCES question_fields(version_id,field_id)
);
CREATE TABLE IF NOT EXISTS questionnaire_rules (
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
CREATE TABLE IF NOT EXISTS subjects (
 subject_id TEXT PRIMARY KEY, external_subject_ref TEXT UNIQUE, is_synthetic INTEGER NOT NULL CHECK(is_synthetic IN (0,1))
);
CREATE TABLE IF NOT EXISTS intake_snapshots (
 intake_id TEXT PRIMARY KEY, subject_id TEXT NOT NULL REFERENCES subjects(subject_id),
 name TEXT, protected_identity_ref TEXT, home_phone TEXT, mobile_phone TEXT, address TEXT, email TEXT,
 delivery_methods_json TEXT NOT NULL DEFAULT '[]' CHECK(json_valid(delivery_methods_json)),
 created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, UNIQUE(intake_id,subject_id)
);
CREATE TABLE IF NOT EXISTS sessions (
 session_id TEXT PRIMARY KEY, subject_id TEXT NOT NULL REFERENCES subjects(subject_id),
 version_id TEXT NOT NULL REFERENCES questionnaire_versions(version_id), intake_id TEXT,
 status TEXT NOT NULL CHECK(status IN ('IN_PROGRESS','PAUSED','NEEDS_REVIEW','READY_FOR_REVIEW','COMPLETED')),
 revision INTEGER NOT NULL DEFAULT 0 CHECK(revision>=0), progress_json TEXT NOT NULL DEFAULT '{}' CHECK(json_valid(progress_json)),
 created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, UNIQUE(session_id,version_id),
 FOREIGN KEY(intake_id,subject_id) REFERENCES intake_snapshots(intake_id,subject_id)
);
CREATE TABLE IF NOT EXISTS messages (
 session_id TEXT NOT NULL REFERENCES sessions(session_id), message_id TEXT NOT NULL,
 sequence_no INTEGER NOT NULL, role TEXT NOT NULL CHECK(role IN ('user','assistant','system')),
 content TEXT NOT NULL, request_id TEXT NOT NULL, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY(session_id,message_id), UNIQUE(session_id,sequence_no), UNIQUE(session_id,request_id)
);
CREATE TABLE IF NOT EXISTS extracted_facts (
 session_id TEXT NOT NULL, fact_id TEXT NOT NULL, version_id TEXT NOT NULL, field_id TEXT,
 raw_json TEXT NOT NULL CHECK(json_valid(raw_json)), model_version TEXT, extraction_status TEXT NOT NULL,
 PRIMARY KEY(session_id,fact_id),
 FOREIGN KEY(session_id,version_id) REFERENCES sessions(session_id,version_id),
 FOREIGN KEY(version_id,field_id) REFERENCES question_fields(version_id,field_id)
);
CREATE TABLE IF NOT EXISTS fact_evidence (
 session_id TEXT NOT NULL, fact_id TEXT NOT NULL, message_id TEXT NOT NULL,
 start_offset INTEGER NOT NULL CHECK(start_offset>=0), end_offset INTEGER NOT NULL CHECK(end_offset>start_offset),
 evidence_text TEXT NOT NULL,
 PRIMARY KEY(session_id,fact_id,message_id,start_offset,end_offset),
 FOREIGN KEY(session_id,fact_id) REFERENCES extracted_facts(session_id,fact_id),
 FOREIGN KEY(session_id,message_id) REFERENCES messages(session_id,message_id)
);
CREATE TABLE IF NOT EXISTS answers (
 session_id TEXT NOT NULL, answer_id TEXT NOT NULL, version_id TEXT NOT NULL, field_id TEXT NOT NULL,
 repeat_key TEXT NOT NULL DEFAULT '', current_revision INTEGER,
 PRIMARY KEY(session_id,answer_id), UNIQUE(session_id,field_id,repeat_key),
 UNIQUE(session_id,answer_id,version_id,field_id),
 FOREIGN KEY(session_id,version_id) REFERENCES sessions(session_id,version_id),
 FOREIGN KEY(version_id,field_id) REFERENCES question_fields(version_id,field_id),
 FOREIGN KEY(session_id,answer_id,current_revision) REFERENCES answer_revisions(session_id,answer_id,revision_no) DEFERRABLE INITIALLY DEFERRED
);
CREATE TABLE IF NOT EXISTS answer_revisions (
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
CREATE TABLE IF NOT EXISTS answer_sources (
 session_id TEXT NOT NULL, answer_id TEXT NOT NULL, revision_no INTEGER NOT NULL, fact_id TEXT NOT NULL,
 PRIMARY KEY(session_id,answer_id,revision_no,fact_id),
 FOREIGN KEY(session_id,answer_id,revision_no) REFERENCES answer_revisions(session_id,answer_id,revision_no),
 FOREIGN KEY(session_id,fact_id) REFERENCES extracted_facts(session_id,fact_id)
);
CREATE TABLE IF NOT EXISTS finalizations (
 finalization_id TEXT PRIMARY KEY, session_id TEXT NOT NULL REFERENCES sessions(session_id),
 session_revision INTEGER NOT NULL, confirmation_message_id TEXT NOT NULL,
 completion_scope TEXT NOT NULL CHECK(completion_scope IN ('HEALTH_QUESTIONS','FULL_FORM')),
 snapshot_json TEXT NOT NULL CHECK(json_valid(snapshot_json)), created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
 UNIQUE(session_id,session_revision,completion_scope),
 FOREIGN KEY(session_id,confirmation_message_id) REFERENCES messages(session_id,message_id)
);
CREATE VIEW IF NOT EXISTS current_answers AS
 SELECT a.repeat_key,r.* FROM answers a JOIN answer_revisions r
 ON r.session_id=a.session_id AND r.answer_id=a.answer_id AND r.revision_no=a.current_revision;

CREATE TRIGGER IF NOT EXISTS evidence_is_user_text BEFORE INSERT ON fact_evidence BEGIN
 SELECT CASE WHEN NOT EXISTS(SELECT 1 FROM messages m WHERE m.session_id=NEW.session_id AND m.message_id=NEW.message_id
  AND m.role='user' AND NEW.end_offset<=length(m.content)
  AND substr(m.content,NEW.start_offset+1,NEW.end_offset-NEW.start_offset)=NEW.evidence_text)
 THEN RAISE(ABORT,'evidence_mismatch') END;
END;
CREATE TRIGGER IF NOT EXISTS valid_repeat_key BEFORE INSERT ON answers BEGIN
 SELECT CASE WHEN NOT EXISTS(SELECT 1 FROM question_fields f,json_each(f.repeat_keys_json) k
 WHERE f.version_id=NEW.version_id AND f.field_id=NEW.field_id AND k.value=NEW.repeat_key)
 THEN RAISE(ABORT,'invalid_repeat_key') END;
END;
CREATE TRIGGER IF NOT EXISTS answer_type BEFORE INSERT ON answer_revisions BEGIN
 SELECT CASE WHEN EXISTS(SELECT 1 FROM question_fields f WHERE f.version_id=NEW.version_id AND f.field_id=NEW.field_id AND
 ((NEW.value_boolean IS NOT NULL AND f.data_type!='boolean') OR (NEW.value_number IS NOT NULL AND f.data_type NOT IN ('number','integer'))
 OR (NEW.value_option IS NOT NULL AND f.data_type!='option') OR (NEW.value_text IS NOT NULL AND f.data_type!='text')
 OR (f.data_type='integer' AND NEW.value_number!=cast(NEW.value_number AS INTEGER))
 OR (NEW.value_number<json_extract(f.constraints_json,'$.minimum'))
 OR (NEW.value_number>json_extract(f.constraints_json,'$.maximum'))
 OR (NEW.value_number<=json_extract(f.constraints_json,'$.exclusive_minimum'))))
 THEN RAISE(ABORT,'invalid_answer_type_or_range') END;
END;
CREATE TRIGGER IF NOT EXISTS answer_history_no_update BEFORE UPDATE ON answer_revisions BEGIN SELECT RAISE(ABORT,'immutable_answer_history'); END;
CREATE TRIGGER IF NOT EXISTS answer_history_no_delete BEFORE DELETE ON answer_revisions BEGIN SELECT RAISE(ABORT,'immutable_answer_history'); END;
CREATE TRIGGER IF NOT EXISTS finalization_no_update BEFORE UPDATE ON finalizations BEGIN SELECT RAISE(ABORT,'immutable_finalization'); END;
CREATE TRIGGER IF NOT EXISTS finalization_no_delete BEFORE DELETE ON finalizations BEGIN SELECT RAISE(ABORT,'immutable_finalization'); END;
CREATE TRIGGER IF NOT EXISTS finalization_revision BEFORE INSERT ON finalizations BEGIN
 SELECT CASE WHEN NOT EXISTS(SELECT 1 FROM sessions s JOIN messages m ON m.session_id=s.session_id
 WHERE s.session_id=NEW.session_id AND s.revision=NEW.session_revision AND s.status='READY_FOR_REVIEW'
 AND m.message_id=NEW.confirmation_message_id AND m.role='user') THEN RAISE(ABORT,'invalid_final_confirmation') END;
END;
