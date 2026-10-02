# 건강 문진 학습 데이터 100건 인수인계

이 패키지는 **정답 라벨이 붙은 합성 사례 100건**과 **설문 DB 구조를 이해할 수 있는 SQL·SQLite·설명 문서**를 제공합니다. RAG 데이터와 모델 가중치는 포함하지 않습니다.

## 1. 처음 보는 분의 확인 순서

1. [100건 검토 화면](data/review.html)을 브라우저로 열어 질문·사용자 답변·A 정답·B 정답을 확인합니다. 전체 이전 대화는 사례별로 펼칠 수 있습니다.
2. [학습 데이터 설명](docs/DATASET_GUIDE.md)에서 라벨과 학습 입력 구조를 확인합니다.
3. [DB·SQL 구조 설명](docs/DB_SQL_GUIDE.md)에서 저장 구조와 역할을 확인합니다.
4. 자세한 컬럼·외래키는 [전체 컬럼 사전](docs/DATA_DICTIONARY.md), 정확한 CHECK·트리거 정의는 [schema.sql](db/schema.sql)을 확인합니다.

## 2. 구성

| 경로 | 내용 |
|---|---|
| `data/master.jsonl` | 사용자 답변 100건, 정답·대화·처리 전후 상태·행동·출처 |
| `data/extraction.jsonl` | LoRA-A 추출 학습 후보 100행 |
| `data/response.jsonl` | LoRA-B 응답 학습 후보 100행 |
| `data/review_queue.jsonl` | A/B 한 쌍을 한 항목으로 묶은 검수 대기 100건 |
| `data/review.html` | 사람이 보기 위한 전체 검토 화면 |
| `data/review.csv` | 스프레드시트로 열 수 있는 검토표, UTF-8 BOM |
| `data/manifest.json` | 데이터 생성 방식·분포·검증 결과·원천 해시 |
| `schema/questionnaire_schema.json` | 기존 공식 문진표 기반 설문 정의 |
| `db/schema.sql` | 기본 15개 테이블·현재 답변 뷰·8개 트리거 |
| `db/service_schema.sql` | 요청 재시도 기록용 `session_events` 추가 |
| `db/questionnaire_reference.sqlite3` | 설문 정의를 넣은 16개 테이블의 SQLite 참조 DB |
| `db/initialized_database.sql` | 참조 DB의 구조와 초기 정의 데이터 전체 SQL 덤프 |
| `docs/` | 데이터·DB 설명과 컬럼 사전 |
| `PACKAGE_MANIFEST.json` | 패키지 전체 파일의 크기·SHA-256 |

**A 100행과 B 100행은 같은 100개 사례를 역할별로 나눈 것입니다. 독립 사례 200건 또는 전체 문진 100세션이 아닙니다.**

## 3. 생성 방식과 현재 상태

- Codex가 사용자 발화와 정답 규칙을 작성하고 Python 생성기로 파일을 생성했습니다.
- 이전 대화·처리 전 상태는 기존 v5 개발 시나리오를 이어받았습니다.
- B 응답은 기존 v6 질문 렌더러로 생성했습니다.
- 별도 Qwen/Ollama 호출과 AI Hub donor 기반 표현 증강은 수행하지 않았습니다.
- 모든 행은 `development`, `human_review=pending`입니다. 독립 사람 검수는 0건입니다.
- 학습·모델 성능 평가·토큰 길이 검사는 수행하지 않았습니다.

라벨 형식·근거 위치·100건 상태 전이를 검사했습니다. 정정 6건은 이전 답변 입력부터 재생하고, 정정 대상 관계를 제거하면 덮어쓰기를 거부하는지도 확인했습니다. 기존 테스트는 작업용 복사본의 Windows 경로 해석을 Linux에 맞게 보정한 뒤 76개 통과했습니다. 자동 검사는 독립적인 사람의 의미 검수를 대신하지 않습니다.

## 4. DB와 이번 100건의 관계

동봉 SQLite에는 문항·필드·선택지·규칙 **정의만** 들어 있습니다. 대상자·문진 세션·답변은 0건입니다. 이번 100건의 라벨·상태는 JSONL에 있으며 SQLite에 환자 세션으로 적재하지 않았습니다.

참조 DB는 기존 정의 DB를 복사한 뒤 `service_schema.sql`을 적용해 준비했습니다. 운영 승인 상태는 `LOCAL_PROTOTYPE`입니다. 원본 DB와 기존 데이터는 수정하지 않았습니다.

## 5. 사용 범위와 다음 단계

1. 검토본에서 값·부정·기간·단위·대상자·정정 대상·근거·응답을 검수합니다.
2. 변경은 Master에 반영하고 A/B 투영과 상태 검증을 다시 수행합니다.
3. 모델에 맞는 채팅 템플릿·토큰 길이·completion 구간 학습 설정을 점검합니다.
4. 검수 승인본을 학습 후보로 확정합니다. 같은 계보를 무작위로 train/test에 나누지 않습니다.

모든 사례는 `shared_authored_pilot_templates` 계보를 공유합니다. 별도 독립 평가 데이터가 필요합니다. 이 묶음은 검토·구조 확인용으로 독립 열람할 수 있지만, 생성기·진행 엔진 전체 실행 환경은 포함하지 않습니다. 재생성에는 기존 인수인계 프로젝트와 `build_labeled_100.py`가 필요합니다.
