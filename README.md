## 신규 후보자 AI 테스트 안내

1. 아래 `docs/` 3편을 순서대로 읽습니다.
2. **4번 문서(Hands-On Lab)를 문서에 나온 그대로 직접 수행**합니다. Step 0부터 끝까지 실습하세요.
3. 실습 중 문서 설명과 실제 동작이 다르거나, 막히는 지점, 사실 오류, 개선하면 좋을 점을 스스로 찾습니다.
4. 이 저장소에 **Issue를 새로 생성**해 발견한 문제를 하나씩 보고합니다 (별도 권한이나 fork 없이 바로 작성 가능). 각 issue에는 다음을 포함하세요.
   - 위치 (파일명:줄 또는 섹션)
   - 재현 방법과 실제 결과
   - 문제가 되는 이유
   - (선택) 수정 제안

정답지는 제공되지 않습니다. 직접 실습하며 찾은 내용만 제출해 주세요.

---

# The Agentic Coding Playbook

A training series on the methodology of putting AI coding agents (Claude Code, Codex, …) to work —
and the environments that run them.

## Contents

| # | Document | Covers |
|---|---|---|
| 1 | Graph Computing *(separate material)* | Treating a codebase as a knowledge graph — maintained outside this repository |
| 2 | [Meta Prompting · Harness Engineering · Loop Engineering](docs/meta-prompting-harness-loop-engineering.md) | The three disciplines of directing AI agents + token-cost strategy (Qwen subscription × Claude Code/Codex, CCR·CCH·cc-switch) |
| 3 | [Orca — ADE Guide](docs/orca-ade-guide.md) | Running a fleet of parallel coding agents in the Orca Agent Development Environment |
| 4 | [Hands-On Lab — Parallel Agents with Orca](docs/lab-orca-parallel-agents.md) | 30-min lab: spawn 3 agents in parallel → monitor → merge → recover from the semantic-conflict trap. Every command validated in a real rehearsal |

## Reading Order

1. Start with **Part 2 (methodology)** to build the conceptual foundation —
   meta prompting (what to ask) × harness (in what environment) × loop (how to iterate and converge).
2. Then see how those concepts materialize in a real tool in **Part 3 (Orca)**,
3. and internalize the parallel-agent workflow by following **Part 4 (hands-on lab)** yourself.

## Core Message

> Move from "prompting well once" to **engineering a system that runs well on its own**.
> Design the prompts, the harness, and the loops — then apply them to many tasks at once in an ADE.
