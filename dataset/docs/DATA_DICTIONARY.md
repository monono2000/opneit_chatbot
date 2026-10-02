# DB 전체 컬럼 사전

동봉된 `db/questionnaire_reference.sqlite3`에서 직접 조회한 구조입니다. SQL 제약·트리거 원문은 `db/schema.sql`, 추가 테이블은 `db/service_schema.sql`을 확인하세요.

## answer_revisions

| 컬럼 | SQLite 선언형 | NOT NULL 선언 | 기본값 | 복합 PK 순번 |
|---|---|---|---|---|
| session_id | TEXT | True | — | 1 |
| answer_id | TEXT | True | — | 2 |
| revision_no | INTEGER | True | — | 3 |
| version_id | TEXT | True | — | — |
| field_id | TEXT | True | — | — |
| previous_revision | INTEGER | False | — | — |
| resolution_status | TEXT | True | — | — |
| applicability_status | TEXT | True | — | — |
| value_boolean | INTEGER | False | — | — |
| value_number | REAL | False | — | — |
| value_option | TEXT | False | — | — |
| value_text | TEXT | False | — | — |
| precision | TEXT | True | 'exact' | — |
| change_reason | TEXT | True | — | — |
| actor | TEXT | True | — | — |
| ruleset_version | TEXT | True | — | — |
| created_at | TEXT | True | CURRENT_TIMESTAMP | — |

외래키:

- FK 0, 구성 순번 0: `version_id` → `field_options.version_id`
- FK 0, 구성 순번 1: `field_id` → `field_options.field_id`
- FK 0, 구성 순번 2: `value_option` → `field_options.option_code`
- FK 1, 구성 순번 0: `session_id` → `answer_revisions.session_id`
- FK 1, 구성 순번 1: `answer_id` → `answer_revisions.answer_id`
- FK 1, 구성 순번 2: `previous_revision` → `answer_revisions.revision_no`
- FK 2, 구성 순번 0: `session_id` → `answers.session_id`
- FK 2, 구성 순번 1: `answer_id` → `answers.answer_id`
- FK 2, 구성 순번 2: `version_id` → `answers.version_id`
- FK 2, 구성 순번 3: `field_id` → `answers.field_id`

## answer_sources

| 컬럼 | SQLite 선언형 | NOT NULL 선언 | 기본값 | 복합 PK 순번 |
|---|---|---|---|---|
| session_id | TEXT | True | — | 1 |
| answer_id | TEXT | True | — | 2 |
| revision_no | INTEGER | True | — | 3 |
| fact_id | TEXT | True | — | 4 |

외래키:

- FK 0, 구성 순번 0: `session_id` → `extracted_facts.session_id`
- FK 0, 구성 순번 1: `fact_id` → `extracted_facts.fact_id`
- FK 1, 구성 순번 0: `session_id` → `answer_revisions.session_id`
- FK 1, 구성 순번 1: `answer_id` → `answer_revisions.answer_id`
- FK 1, 구성 순번 2: `revision_no` → `answer_revisions.revision_no`

## answers

| 컬럼 | SQLite 선언형 | NOT NULL 선언 | 기본값 | 복합 PK 순번 |
|---|---|---|---|---|
| session_id | TEXT | True | — | 1 |
| answer_id | TEXT | True | — | 2 |
| version_id | TEXT | True | — | — |
| field_id | TEXT | True | — | — |
| repeat_key | TEXT | True | '' | — |
| current_revision | INTEGER | False | — | — |

외래키:

- FK 0, 구성 순번 0: `session_id` → `answer_revisions.session_id`
- FK 0, 구성 순번 1: `answer_id` → `answer_revisions.answer_id`
- FK 0, 구성 순번 2: `current_revision` → `answer_revisions.revision_no`
- FK 1, 구성 순번 0: `version_id` → `question_fields.version_id`
- FK 1, 구성 순번 1: `field_id` → `question_fields.field_id`
- FK 2, 구성 순번 0: `session_id` → `sessions.session_id`
- FK 2, 구성 순번 1: `version_id` → `sessions.version_id`

## extracted_facts

| 컬럼 | SQLite 선언형 | NOT NULL 선언 | 기본값 | 복합 PK 순번 |
|---|---|---|---|---|
| session_id | TEXT | True | — | 1 |
| fact_id | TEXT | True | — | 2 |
| version_id | TEXT | True | — | — |
| field_id | TEXT | False | — | — |
| raw_json | TEXT | True | — | — |
| model_version | TEXT | False | — | — |
| extraction_status | TEXT | True | — | — |

외래키:

- FK 0, 구성 순번 0: `version_id` → `question_fields.version_id`
- FK 0, 구성 순번 1: `field_id` → `question_fields.field_id`
- FK 1, 구성 순번 0: `session_id` → `sessions.session_id`
- FK 1, 구성 순번 1: `version_id` → `sessions.version_id`

## fact_evidence

| 컬럼 | SQLite 선언형 | NOT NULL 선언 | 기본값 | 복합 PK 순번 |
|---|---|---|---|---|
| session_id | TEXT | True | — | 1 |
| fact_id | TEXT | True | — | 2 |
| message_id | TEXT | True | — | 3 |
| start_offset | INTEGER | True | — | 4 |
| end_offset | INTEGER | True | — | 5 |
| evidence_text | TEXT | True | — | — |

외래키:

- FK 0, 구성 순번 0: `session_id` → `messages.session_id`
- FK 0, 구성 순번 1: `message_id` → `messages.message_id`
- FK 1, 구성 순번 0: `session_id` → `extracted_facts.session_id`
- FK 1, 구성 순번 1: `fact_id` → `extracted_facts.fact_id`

## field_options

| 컬럼 | SQLite 선언형 | NOT NULL 선언 | 기본값 | 복합 PK 순번 |
|---|---|---|---|---|
| version_id | TEXT | True | — | 1 |
| field_id | TEXT | True | — | 2 |
| option_code | TEXT | True | — | 3 |
| label | TEXT | True | — | — |

외래키:

- FK 0, 구성 순번 0: `version_id` → `question_fields.version_id`
- FK 0, 구성 순번 1: `field_id` → `question_fields.field_id`

## finalizations

| 컬럼 | SQLite 선언형 | NOT NULL 선언 | 기본값 | 복합 PK 순번 |
|---|---|---|---|---|
| finalization_id | TEXT | False | — | 1 |
| session_id | TEXT | True | — | — |
| session_revision | INTEGER | True | — | — |
| confirmation_message_id | TEXT | True | — | — |
| completion_scope | TEXT | True | — | — |
| snapshot_json | TEXT | True | — | — |
| created_at | TEXT | True | CURRENT_TIMESTAMP | — |

외래키:

- FK 0, 구성 순번 0: `session_id` → `messages.session_id`
- FK 0, 구성 순번 1: `confirmation_message_id` → `messages.message_id`
- FK 1, 구성 순번 0: `session_id` → `sessions.session_id`

## intake_snapshots

| 컬럼 | SQLite 선언형 | NOT NULL 선언 | 기본값 | 복합 PK 순번 |
|---|---|---|---|---|
| intake_id | TEXT | False | — | 1 |
| subject_id | TEXT | True | — | — |
| name | TEXT | False | — | — |
| protected_identity_ref | TEXT | False | — | — |
| home_phone | TEXT | False | — | — |
| mobile_phone | TEXT | False | — | — |
| address | TEXT | False | — | — |
| email | TEXT | False | — | — |
| delivery_methods_json | TEXT | True | '[]' | — |
| created_at | TEXT | True | CURRENT_TIMESTAMP | — |

외래키:

- FK 0, 구성 순번 0: `subject_id` → `subjects.subject_id`

## messages

| 컬럼 | SQLite 선언형 | NOT NULL 선언 | 기본값 | 복합 PK 순번 |
|---|---|---|---|---|
| session_id | TEXT | True | — | 1 |
| message_id | TEXT | True | — | 2 |
| sequence_no | INTEGER | True | — | — |
| role | TEXT | True | — | — |
| content | TEXT | True | — | — |
| request_id | TEXT | True | — | — |
| created_at | TEXT | True | CURRENT_TIMESTAMP | — |

외래키:

- FK 0, 구성 순번 0: `session_id` → `sessions.session_id`

## question_fields

| 컬럼 | SQLite 선언형 | NOT NULL 선언 | 기본값 | 복합 PK 순번 |
|---|---|---|---|---|
| version_id | TEXT | True | — | 1 |
| field_id | TEXT | True | — | 2 |
| item_id | TEXT | True | — | — |
| field_name | TEXT | True | — | — |
| data_type | TEXT | True | — | — |
| unit | TEXT | False | — | — |
| constraints_json | TEXT | True | — | — |
| repeat_keys_json | TEXT | True | — | — |
| source_locator | TEXT | True | — | — |

외래키:

- FK 0, 구성 순번 0: `version_id` → `question_items.version_id`
- FK 0, 구성 순번 1: `item_id` → `question_items.item_id`

## question_items

| 컬럼 | SQLite 선언형 | NOT NULL 선언 | 기본값 | 복합 PK 순번 |
|---|---|---|---|---|
| version_id | TEXT | True | — | 1 |
| item_id | TEXT | True | — | 2 |
| official_number | TEXT | True | — | — |
| section_name | TEXT | True | — | — |
| question_text | TEXT | True | — | — |
| subject_label | TEXT | False | — | — |
| sequence_no | INTEGER | True | — | — |
| reference_period | TEXT | False | — | — |
| instructions | TEXT | False | — | — |
| source_page | INTEGER | True | — | — |
| source_locator | TEXT | True | — | — |

외래키:

- FK 0, 구성 순번 0: `version_id` → `questionnaire_versions.version_id`

## questionnaire_rules

| 컬럼 | SQLite 선언형 | NOT NULL 선언 | 기본값 | 복합 PK 순번 |
|---|---|---|---|---|
| version_id | TEXT | True | — | 1 |
| rule_id | TEXT | True | — | 2 |
| kind | TEXT | True | — | — |
| item_id | TEXT | False | — | — |
| field_id | TEXT | False | — | — |
| condition_json | TEXT | False | — | — |
| origin | TEXT | True | — | — |
| status | TEXT | True | — | — |
| description | TEXT | True | — | — |
| source_locator | TEXT | False | — | — |

외래키:

- FK 0, 구성 순번 0: `version_id` → `question_fields.version_id`
- FK 0, 구성 순번 1: `field_id` → `question_fields.field_id`
- FK 1, 구성 순번 0: `version_id` → `question_items.version_id`
- FK 1, 구성 순번 1: `item_id` → `question_items.item_id`
- FK 2, 구성 순번 0: `version_id` → `questionnaire_versions.version_id`

## questionnaire_versions

| 컬럼 | SQLite 선언형 | NOT NULL 선언 | 기본값 | 복합 PK 순번 |
|---|---|---|---|---|
| version_id | TEXT | False | — | 1 |
| title | TEXT | True | — | — |
| form_revision_date | TEXT | True | — | — |
| source_path | TEXT | True | — | — |
| source_sha256 | TEXT | True | — | — |
| schema_sha256 | TEXT | True | — | — |
| policy_version | TEXT | True | — | — |
| status | TEXT | True | — | — |

외래키:

- 없음

## session_events

| 컬럼 | SQLite 선언형 | NOT NULL 선언 | 기본값 | 복합 PK 순번 |
|---|---|---|---|---|
| session_id | TEXT | True | — | 1 |
| request_id | TEXT | True | — | 2 |
| kind | TEXT | True | — | — |
| payload_sha256 | TEXT | True | — | — |
| result_json | TEXT | True | — | — |
| created_at | TEXT | True | CURRENT_TIMESTAMP | — |

외래키:

- FK 0, 구성 순번 0: `session_id` → `sessions.session_id`

## sessions

| 컬럼 | SQLite 선언형 | NOT NULL 선언 | 기본값 | 복합 PK 순번 |
|---|---|---|---|---|
| session_id | TEXT | False | — | 1 |
| subject_id | TEXT | True | — | — |
| version_id | TEXT | True | — | — |
| intake_id | TEXT | False | — | — |
| status | TEXT | True | — | — |
| revision | INTEGER | True | 0 | — |
| progress_json | TEXT | True | '{}' | — |
| created_at | TEXT | True | CURRENT_TIMESTAMP | — |

외래키:

- FK 0, 구성 순번 0: `intake_id` → `intake_snapshots.intake_id`
- FK 0, 구성 순번 1: `subject_id` → `intake_snapshots.subject_id`
- FK 1, 구성 순번 0: `version_id` → `questionnaire_versions.version_id`
- FK 2, 구성 순번 0: `subject_id` → `subjects.subject_id`

## subjects

| 컬럼 | SQLite 선언형 | NOT NULL 선언 | 기본값 | 복합 PK 순번 |
|---|---|---|---|---|
| subject_id | TEXT | False | — | 1 |
| external_subject_ref | TEXT | False | — | — |
| is_synthetic | INTEGER | True | — | — |

외래키:

- 없음
