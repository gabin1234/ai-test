# Orca — ADE (AI/Agent Development Environment) Guide

> Part 3 of our AI coding training series — this installment covers Orca, the tool that serves as
> **the stage where you actually put into practice** the concepts from the meta-prompting, harness,
> and loop engineering installments.
> Orca is an "IDE for AI agents" — an **ADE** (officially: Agent Development Environment,
> commonly called an AI Development Environment).

---

## 1. What Is Orca?

**Definition**: [Orca](https://www.onorca.dev/) is an **open-source (MIT) desktop environment for running and supervising
multiple AI coding agents (Claude Code, Codex, Cursor CLI, Gemini CLI, OpenCode, and 30+ others) in parallel,
each in an isolated git worktree**.
It was built by stablyai, is backed by Y Combinator, and is growing fast with 29k+ GitHub stars (as of 2026-07; latest version v1.4.155).

### How It Differs from an IDE — From "Editor" to "Control Tower"

| | IDE (VS Code, etc.) | ADE (Orca) |
|---|---|---|
| Who does the work | A human writes the code | Agents write the code; the human supervises |
| Unit of work | File/project | **One worktree = one task = one agent team** |
| Parallelism | Multiple tabs | Multiple worktrees running **concurrently** |
| Review style | Reading the code directly | Diff review + terminal output + browser verification |

### How It Connects to the Trilogy's Concepts

- **Harness engineering**: Orca is a "harness for harnesses." It wraps harnesses like Claude Code/Codex
  in **one more, larger execution environment**: isolated worktrees, terminals, a browser, emulators, and permissions.
- **Loop engineering**: Each worktree's agent runs its own execute→observe→fix loop,
  while a human (or a coordinator agent) monitors all the loops via `worktree ps`.
  `automations` (scheduled runs) and `orchestration run` (the coordinator loop) are loop-engineering tools in their own right.
- **Meta-prompting**: Since worktree creation injects an initial prompt via `--prompt`,
  Orca pairs naturally with a workflow that stamps out well-designed prompt templates, one per task.

> ⚠️ Good to know: Orca launches worktree agents with `--dangerously-skip-permissions`
> (approval skipping) by default. Given the isolated-worktree premise it's a reasonable default,
> but it means agents run commands without asking — which makes the habit of scoping your prompts
> precisely all the more important.

---

## 2. The Four Core Concepts

1. **Project/Repo**: A codebase registered with Orca. `orca repo add --path <path>`.
2. **Worktree**: An isolated checkout, created one per task.
   Each worktree has its own branch, terminal, browser tab, and context. No file conflicts between them.
3. **Terminal**: A shell/agent session running inside a worktree. Readable, writable, and awaitable via the CLI.
4. **Agent**: A coding agent (claude, codex, etc.) attached to a worktree.
   At creation time, `--agent` and `--prompt` specify "who does what."

---

## 3. Installation and Getting Started

```bash
# Install the desktop app: download from https://www.onorca.dev/ (macOS/Windows/Linux)
# The CLI ships with the app

orca open          # Launch the app and wait for the runtime to be ready
orca status --json # Check runtime readiness
orca repo add --path ~/my-project   # Register a project
```

Most CLI commands require a **running Orca runtime**. If it isn't open, start with `orca open`.
For headless servers use `orca serve`; to connect a remote runtime, use `orca environment add --pairing-code ...`.

---

## 4. Hands-On — Running Agents in Parallel

### 4-1. Create a Worktree + Agent per Task

```bash
# Create a worktree with an agent and an initial prompt attached
orca worktree create --name fix-login --agent claude \
  --prompt "Fix the validation bug in the login form and make the tests pass"

# You can also link a GitHub issue or Linear ticket as task context
orca worktree create --name issue-273 --repo name:my-project --issue 273
orca worktree create --name sta-335 --linear-issue STA-335
```

### 4-2. Supervise Everything at Once

```bash
orca worktree ps            # Per-worktree progress summary (the control-tower view)
orca worktree list          # List worktrees
orca file open-changed --mode diff   # Open every changed file as a diff for review
```

> `open-changed` opens **uncommitted (git-changed) files only**. If the agent has already committed,
> review with `git diff main...<branch>` instead.

### 4-3. Remote Terminal Control — Talking to an Agent

```bash
orca terminal list --worktree active --json   # Get terminal handles
orca terminal read --terminal term_123        # Read output
orca terminal send --terminal term_123 --text "Add tests too" --enter
orca terminal wait --terminal term_123 --for exit --timeout-ms 600000  # Wait until exit
```

The `send → wait → read` combination is exactly the **feedback signal / termination condition of loop engineering**, implemented via the CLI.

### 4-4. Multi-Agent Orchestration

```bash
orca orchestration task-create ...   # Define a task
orca orchestration dispatch ...      # Assign it to a specific terminal (agent)
orca orchestration send / reply      # Messages between agents
orca orchestration gate-create ...   # Points requiring human approval (decision gates)
orca orchestration run               # Start the coordinator loop
```

**Structured multi-agent collaboration** is built in: agents exchange threaded messages,
and the flow is controlled through task DAGs and decision gates.

### 4-5. Built-In Browser, Computer Use, and Mobile Emulators

```bash
# Built-in browser: agents verify the web app they just built, themselves
orca tab create --url http://localhost:3000
orca snapshot                     # Accessibility tree + element refs (e1, e2...)
orca click --element e3
orca fill --element e5 --value "hello"
orca screenshot

# Desktop app control (computer use)
orca computer list-apps
orca computer get-app-state ...

# iOS simulator / Android emulator
orca emulator list
orca emulator tap 0.5 0.5
```

The key point is that even the "look at the screen and verify" loop lives inside the harness.

### 4-6. Automations (Scheduled Loops)

```bash
orca automations create ...   # Register an agent job that runs on a schedule
orca automations runs         # Check run history
```

---

## 5. Bundled Skills — How Agents Learn Orca

The Orca CLI ships with agent-facing guides built in as skills:

```bash
orca skills list              # List them
orca skills get orca-cli      # The guide itself (Markdown)
orca agent-context --json     # Machine-readable command schema
```

| Skill | Contents |
|---|---|
| `orca-cli` | Worktrees, terminals, repos, and built-in browser control end to end |
| `orchestration` | Multi-agent messaging / task DAGs / decision gates / coordinator loop |
| `computer-use` | Accessibility-tree-based desktop app control |
| `orca-emulator` / `orca-emulator-android` | iOS/Android emulator control |
| `orca-linear` | Reading Linear tickets, moving statuses, attaching PR links |
| `orca-per-workspace-env` | Recipes for per-workspace disposable execution environments (VMs/sandboxes) |

When an agent like Claude Code comes up inside Orca, it **learns to operate Orca on its own** through these skills —
a design where "the harness teaches the agent how to use it."

---

## 6. Recommended Workflow

1. Register the project with `orca repo add`
2. Break the work into tasks and run `worktree create --agent claude --prompt "..."` for each one (using templates built with meta-prompting)
3. Supervise with `worktree ps`; intervene on stuck agents with `terminal send`
4. Review finished worktrees as diffs, then merge (`file open-changed --mode diff` for uncommitted changes, `git diff main...<branch>` for committed work)
5. Promote recurring work to `automations` and multi-step collaboration to `orchestration`
6. Clean up finished worktrees with `worktree rm`

**One-line summary**: Orca is the stage where you execute what the earlier installments taught — "building systems that run well on their own."
It's the tool for applying prompts (meta-prompting) × execution environment (harness) × iteration structure (loops) to **many tasks at once**.

---

## 7. References

- Official site: https://www.onorca.dev/
- Official X account: https://x.com/orca_build
- Reviews and write-ups:
  - [Orca Review: The IDE Built for Parallel Coding Agents](https://dev.to/andrew-ooo/orca-review-the-ide-built-for-parallel-coding-agents-15df)
  - [Orca Explained: A Free ADE for Parallel AI Coding Agents](https://qjc.app/en/blog/orca-parallel-agents)
  - [The Complete Guide to the Orca IDE](https://agmazon.com/blog/articles/technology/202607/orca-ade-guide-en.html)
  - [Orca: ADE for Running a Fleet of Parallel AI Coding Agents](https://pyshine.com/Orca-Agent-Development-Environment-Parallel-AI-Coding/)
- The CLI examples in this document were verified against the `orca --help` / `orca skills list` output of a locally installed Orca v1.4.155 (2026-07-25).
