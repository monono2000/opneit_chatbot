# 100건 데이터와 정답 라벨 설명

## 1. 무엇을 학습시키는가

| 역할 | 입력 | 정답 | 맡지 않는 일 |
|---|---|---|---|
| A: 정보 추출 | 설문 카탈로그, 현재 사용자 발화까지의 대화, 처리 전 상태 | 사실·의도·정정 관계·원문 근거 JSON | 다음 행동 결정, 점수 계산, DB 직접 쓰기 |
| 코드 | A 추출 후보, 기존 상태, 명시적 확인 이벤트 | 검증 결과·정규화 값·다음 행동 | 사용자에게 없는 사실 생성 |
| B: 응답 표현 | 대화, 처리 후 상태, 코드가 정한 행동 계획 | 한국어 응답 한 문장 또는 문단 | 설문값·분기·행동 변경 |

Master는 학습용 원본입니다. 최종 답변을 저장하는 서비스 DB와 다르게 **입력 문맥·정답·검수 상태·계보**까지 보관합니다. A/B에는 역할에 필요한 정보만 투영합니다.

## 2. 수량과 분포

| 사례 종류 | 건수 |
|---|---:|
| 질환별 진단·현재 복약 | 22 |
| 가족력 | 10 |
| B형간염 공식 선택지 | 3 |
| 흡연 경험 | 3 |
| 근력 운동 일수 | 8 |
| 고강도·중강도 활동 일수 | 6 |
| 액상형 전자담배 사용 일수 경계 | 8 |
| 음주 빈도 | 6 |
| 신체활동 시간 | 4 |
| 주종별 음주량 | 2 |
| 흡연 상세 정보 | 2 |
| 진단만 답한 부분 응답 | 6 |
| 단위 누락 | 2 |
| 모호함·기억 불확실 | 6 |
| 질문 목적·거절·보류 의도 | 6 |
| 이전 일수 답변 정정 | 6 |
| **합계** | **100** |

31개 내부 문항을 모두 포함하지만, 모든 필드·값·선택지 조합을 포괄하지 않습니다. 새 답변은 작성한 문장 틀을 공유하며 표현 다양성은 제한적입니다. 충돌 확인 `CONFIRM` 및 최종 확정 `COMPLETE` 행동은 이번 100건에 없습니다.

## 3. Master 한 행의 구조

| 키 | 의미 |
|---|---|
| `id` | `labeled100_001`부터 `labeled100_100`까지 |
| `category`, `item_id` | 사례 종류와 대상 내부 문항 |
| `source_turn_id` | 기반 문맥을 가져온 v5 턴 ID |
| `lineage_group` | 원천 템플릿 계보; 분할 누출 방지에 사용 |
| `split`, `human_review` | 현재 `development`, `pending` |
| `context` | 과거 대화부터 현재 사용자 발화까지; 마지막 행이 이번 입력 |
| `state_before` | 이번 사용자 발화를 처리하기 전 상태 |
| `labels` | A 정답 JSON |
| `state_after` | 라벨을 기존 진행 엔진으로 처리한 결과 |
| `plan` | 코드의 다음 행동; Master에는 기존 `assistant_text`도 남아 있음 |
| `response` | 별도 v6 렌더러가 만든 실제 B 정답 |
| `setup_turn` | 정정 6건의 이전 답변·라벨·상태 전이. 다른 사례는 null |

`plan.assistant_text`와 `response`의 표현은 다를 수 있습니다. **B의 정답은 `response`**이며 B 입력 계획에서는 `assistant_text`를 제거했습니다. A에는 현재 턴 처리 후 상태를 넣지 않았습니다.

정정 사례에서는 직전 assistant 응답이 다음 문항 질문일 수 있습니다. 사용자가 이전 답을 고치는 상황이므로 정정 대상은 직전 질문이 아니라 `correction_target`이 지정한 기존 답입니다.

## 4. A 정답 계약

최상위 키는 네 개입니다.

```json
{"facts": [], "intents": [], "relations": [], "unmapped_facts": []}
```

`facts`는 `item_id`, `field`, `value`, `semantic_status`, `precision`, `evidence`를 갖습니다.

| 축 | 값 |
|---|---|
| 사실 상태 | `ANSWERED`, `AMBIGUOUS`, `MISSING`, `UNCERTAIN` |
| 정밀도 | `exact`, `approximate`, `range`, `unspecified` |
| 발화 의도 | `ANSWER`, `ASK_PURPOSE`, `REQUEST_SKIP`, `REFUSED`, `OFF_TOPIC` |
| 진술 관계 | `NEW_INFORMATION`, `CORRECTION`, `CONFLICT` |

위 목록은 기존 계약의 허용값입니다. 이번 100건에 모든 유형이 등장하는 것은 아닙니다.

`evidence`에는 `turn_index`, `start`, `end`, `text`가 있습니다. `context[turn_index]`의 사용자 문자열을 Python 문자 인덱스 `[start:end]`로 자른 결과가 `text`와 같아야 합니다. 숫자뿐 아니라 부정·기간·대상자를 판별하는 의미도 함께 검토해야 합니다.

`CORRECTION`에는 과거 사용자 발화 위치와 수정할 문항·필드를 지정하는 `correction_target`이 있습니다. 거절·모름·단위 누락은 임의로 0이나 false로 바꾸지 않습니다. Q3의 `unknown`은 정식 선택지이며 `UNCERTAIN` 상태와 다릅니다.

## 5. 실제 파일 읽기

패키지 루트에서 Python 표준 라이브러리만으로 열 수 있습니다.

```python
import json
from pathlib import Path

rows = [json.loads(line) for line in Path('data/master.jsonl').read_text(encoding='utf-8').splitlines()]
row = rows[0]
print(row['context'][-1]['content'])
print(json.dumps(row['labels'], ensure_ascii=False, indent=2))
print(row['response'])
```

`extraction.jsonl`과 `response.jsonl`은 각각 `prompt` 메시지 배열과 `completion` 메시지 배열을 가집니다. A completion의 내용은 JSON 문자열, B completion의 내용은 한국어 응답입니다. 학습 도구에 맞춰 메시지 배열을 변환하고 completion 영역만 정답 손실 계산에 사용해야 합니다.

## 6. 검수와 해석

- `review.csv`는 한 행에서 사용자 답변·라벨·B 응답을 비교하기 위한 표입니다. 전체 문맥은 `review.html` 또는 Master에서 확인합니다.
- 검수 대상 100건은 A/B 한 쌍 기준입니다. 승인·수정·보류와 검수 이유, 검수자·날짜를 별도로 기록하는 것이 좋습니다.
- 코드 검사는 문자열 근거·구조·정해진 상태 전이를 확인했습니다. 모델의 실제 의미 이해 성능을 측정한 결과는 아닙니다.
- `data/manifest.json`의 원천 경로는 기존 생성 프로젝트 기준입니다. 원천 파일 전체가 이 ZIP에 포함된다는 뜻은 아닙니다.
- JSONL에 환자처럼 보이는 이전 대화가 있어도 합성 개발 시나리오입니다. 실제 수검자 자료로 해석하지 않습니다.
