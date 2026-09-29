# QA 리포트 — AI 트레이닝 자료 실기 검증 (2026-07-25)

> **작성**: QA 워크트리 에이전트 · **수신**: DEV 워크트리 에이전트
> **검증 방법**: 실습 랩(4편)을 Orca v1.4.155 실기기에서 Step 0~5 전체 재현
> (Claude 에이전트 3개 실제 병렬 실행 → 관제 → 개입 → 머지 → 복구 → 정리 완주).
> 2·3편은 `orca --help`/`orca skills list` 대조, 외부 링크 27건 전수 확인(YouTube oEmbed·GitHub API·curl).
> 각 이슈에 한국어 원본과 `docs/en/` 번역본 위치를 함께 표기했으므로 **두 파일을 같이 수정할 것**.

---

## P1 — 학습자가 문서대로 하면 막히는 문제 (필수 수정)

### QA-1. Step 4의 `uvx pytest -q`가 의미적 충돌에 도달하기 전에 ImportError로 죽음

- **위치**: `docs/lab-orca-parallel-agents.md:148`, `docs/en/lab-orca-parallel-agents.md:162`
- **재현**: 머지 후 `cd ~/orca-lab/todo-app && uvx pytest -q` →
  ```
  ImportError while importing test module 'tests/test_todo.py'
  E   ModuleNotFoundError: No module named 'todo'
  1 error in 0.05s
  ```
- **원인**: `uvx pytest`는 격리 venv의 pytest 바이너리를 실행하므로 repo 루트가 `sys.path`에 들어가지 않음.
  이전 리허설에서는 태스크 B 에이전트가 **우연히** 루트에 `conftest.py`를 만들어 통과했던 것 —
  에이전트 산출물에 따라 되기도/안 되기도 하는 비결정적 함정. 이번 실행에서는 conftest.py가 생성되지 않아 실패.
- **영향**: 랩의 핵심 교육 포인트(의미적 충돌로 인한 테스트 실패)에 도달하기 전에 엉뚱한 에러를 먼저 만남.
  학습자는 "테스트 일부 실패"가 아니라 수집(collection) 에러를 보게 되어 문서 서사가 깨짐.
- **검증된 수정안** (둘 다 적용 권장):
  1. Step 4 명령을 `PYTHONPATH=. uvx pytest -q`로 변경 — 실측으로 `4 failed, 5 passed` 도달 확인.
  2. Step 2 태스크 B 프롬프트에 "저장소 루트에서 `pytest`로 바로 실행 가능하게 만들 것 (필요하면 conftest.py 추가)" 조건 추가 — 이 자체가 "종료 조건을 프롬프트에 명시하라"는 메타 프롬프팅 교훈과도 맞음.

### QA-2. Step 4의 `orca file open-changed --mode diff`가 "No changed files."만 출력 — 리뷰 단계가 동작하지 않음

- **위치**: `docs/lab-orca-parallel-agents.md:136`, `docs/en/lab-orca-parallel-agents.md:150`
  (3편 `docs/orca-ade-guide.md:83`·`:169`, `docs/en/orca-ade-guide.md:85`·`:171`에도 같은 캐비앳 필요)
- **재현**: `open-changed`는 **미커밋(git-changed) 파일만** 연다. Step 2 프롬프트가 에이전트에게 "완료되면 커밋해라"를
  지시하므로, 리뷰 시점의 워크트리는 클린 상태 → 실측 결과 `No changed files.` 출력, 아무것도 열리지 않음.
  (미커밋 변경이 있는 워크트리에서는 `Opened 1 changed file targets.`로 정상 동작 — 별도 실측 확인)
- **영향**: 문서의 diff 리뷰 단계가 랩의 실제 흐름과 모순됨. 완주 체크리스트의 "diff 리뷰 후 머지" 항목 수행 불가.
- **수정안**: 커밋된 작업의 리뷰 명령으로 교체 —
  ```bash
  cd ~/orca-lab/todo-app
  git diff main...gabin1234/fix-done-bug     # 브랜치별로 반복
  ```
  그리고 `open-changed`는 "에이전트가 아직 커밋하지 않은 경우"의 도구로 위치를 옮겨 설명.
  3편에는 "open-changed는 미커밋 변경만 연다" 한 줄 캐비앗 추가.

---

## P2 — 사실 오류·부정확한 설명 (수정 권장)

### QA-3. Orca GitHub 스타 수 낡음: "1.3만+" → 실측 29,018

- **위치**: `docs/orca-ade-guide.md:14`, `docs/en/orca-ade-guide.md:16`
- **근거**: `api.github.com/repos/stablyai/orca` → stars 29,018, license MIT (2026-07-25 조회).
  MIT·stablyai 제작·YC 백업 주장은 onorca.dev에서 교차 확인됨 — 스타 수만 갱신하면 됨. "2.9만+" 권장.
- 같은 줄의 "최신 버전 v1.4.15x" 표기도 문서 말미(`:187`)의 "v1.4.155"와 통일 권장.

### QA-4. 브랜치 명명 규칙 설명 부정확: "`<git유저명>/<워크트리이름>`"

- **위치**: `docs/lab-orca-parallel-agents.md:96` (en `:104` 부근)
- **근거**: 이 머신의 git `user.name`은 `sungyong`(global·repo 동일, repo의 Orca `gitUsername` 설정은 빈 값)인데
  실제 생성된 브랜치는 `gabin1234/fix-done-bug`. 접두사는 git 설정이 아니라 **Orca에 로그인된 계정(GitHub 사용자명)**에서 옴.
- **수정안**: "브랜치는 `<Orca 계정명>/<워크트리이름>` 형태로 만들어집니다 (repo 설정의 gitUsername으로 변경 가능)" 수준으로 교정.

### QA-5. "10개 중 4개가 실패" 단정 — 실행마다 달라짐

- **위치**: `docs/lab-orca-parallel-agents.md:156` (en 대응 문장), `marketing/promo-posts.md`의 Tweet 5 "4 failing tests"
- **근거**: 이번 재현에서는 에이전트 B가 테스트 9개를 작성했고 그중 4개 실패. 테스트 개수·실패 개수는 에이전트 산출물에 따라 변동.
  (의미적 충돌 자체는 100% 재현됨 — 실패 원인 4건 전부 "버그 기준 기대값 vs 수정된 구현"이었음. 핵심 주장은 유효.)
- **수정안**: "일부가 실패합니다 (리허설 예: 10개 중 4개)"처럼 예시로 완충. 홍보 글의 "4 failing tests"도 "failing tests"로.

---

## P3 — 개선 제안 (선택)

| # | 내용 | 위치 |
|---|---|---|
| QA-6 | Step 0에 `.gitignore`(`__pycache__/`) 없음 → 학습자가 `git add`할 때 `.pyc`가 딸려 들어감(실측로 재현됨). 추가 권장. 단, `__pycache__` 때문에 `worktree rm --force`를 배우는 Step 5 교육 포인트를 유지하려면 의도적 생략임을 주석으로 명시하는 것도 방법 | lab Step 0 |
| QA-7 | Step 5 정리에 `~/.todo-lab.json`(홈 디렉토리 DB)과 `~/orca-lab` 삭제, `orca repo` 등록 해제 안내 없음 | lab Step 5 |
| QA-8 | 랩 재수행(2회차) 안내 없음 — 기존 디렉토리/등록이 남은 상태에서 Step 0을 다시 붙여넣으면 기존 커밋 위에 덮어씀. "다시 하려면 `rm -rf ~/orca-lab/todo-app` 후 시작" 한 줄 권장 | lab 준비물 또는 Step 0 |
| QA-9 | `worktree rm`은 **머지 안 된** 브랜치를 자동 삭제하지 않고 경고 후 남김(실측: "local branch was kept"). "이미 머지했으니 안전" 문구는 맞지만, 미머지 시 동작도 한 줄 보강 가치 | lab Step 5 |
| QA-10 | 영문 README 목차가 2번부터 시작하는데 1편(그래프 컴퓨팅, 별도 자료) 설명 행이 없음 — 한국어판에는 있음. 구매자가 "1편은 어디 갔나" 의문 가질 수 있음 | `README.md` 영문 표 |
| QA-11 | Medium 참고 링크가 curl 기준 403 (봇 차단으로 추정, 브라우저 확인 권장). 나머지 링크 26건은 전부 유효 | `docs/meta-prompting-harness-loop-engineering.md:200` |
| QA-12 | "차세대 세대를 ADE2로 부르기도 함" — '차세대 세대' 겹말 + ADE2 호칭은 출처 확인 불가. 문구 정리 또는 삭제 권장 | `docs/orca-ade-guide.md:6` |
| QA-13 | Orca는 claude를 `--dangerously-skip-permissions`로 기동함(실측). 격리 워크트리라 합리적이지만 교육 자료로서 안전 주의 한 줄 가치 있음. 또한 이 모드에서는 Step 3의 "권한 승인 대기" 상황이 거의 발생하지 않음 | lab Step 3, guide 1장 |

---

## 검증으로 **확인된** 것들 (수정 불필요 — 자료의 강점)

- Step 0 샘플 코드: 버그 1(1-기반→0-기반 오프셋)·버그 2(IndexError) 모두 문서 설명대로 재현.
- `worktree create/ps/list/rm(--force)`, `terminal list/read/send/wait --for tui-idle`, `repo add/list` — 전 명령 문서 그대로 동작. 브랜치 자동 정리(머지된 경우)도 확인.
- `terminal send` 개입: 실행 중인 write-readme 에이전트에 "알려진 버그 섹션 추가" 지시 → 실제 커밋에 반영됨.
- 3-브랜치 머지 무충돌 + **의미적 충돌 재현**(핵심 교육 포인트 유효) + 복구 후 9 passed.
- `python3 todo.py` (인자 없음) → 사용법 출력 확인 (Step 4 검증 항목 유효).
- 3편 스킬 표 = 실제 `orca skills list`와 일치(레거시 별칭 `linear-tickets`만 표에 없음 — 무해).
- orchestration/automations/emulator/computer/브라우저 명령군 전부 `orca --help`에 실재.
- YouTube 링크 16/16 유효(oEmbed 200). CCR 36,184★("36k+" ✓), CCH 3,272★("3k+" ✓).
- Qwen: 공식 coding-plan 페이지 존재, `sk-sp-` 키 형식·Claude Code 지원 언급 확인 (달러 금액은 페이지가 동적이라 미확인 — 문서의 "결제 전 확인" 완충 문구가 이미 적절).

## DEV 작업 가이드

1. **QA-1·QA-2부터** (학습자 차단 이슈). 수정안의 명령은 이 리포트 작성 과정에서 실기기로 검증된 것.
2. 각 이슈는 한국어 원본 + `docs/en/` 번역본 **양쪽** 수정 필요. P2·P3의 문구 수정 시 홍보 글(`marketing/promo-posts.md`)의 대응 문구도 확인.
3. 수정 후 재검증 최소 세트: `PYTHONPATH=. uvx pytest -q`가 의미적 충돌 실패를 내는지, `git diff main...<브랜치>`가 리뷰 diff를 보여주는지.
