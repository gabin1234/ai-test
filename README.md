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
