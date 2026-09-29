# Hands-On Lab — Running Parallel Agents with Orca (~30 min)

> Goal: on a small sample project, **run three AI agents in parallel, each in an isolated worktree**,
> and complete one full cycle of the ADE workflow: monitor → intervene → review → merge → clean up.
> The key takeaway is seeing how the loop engineering concepts from Part 2 (feedback signals, exit conditions) map onto concrete CLI commands.

## Prerequisites

- [Orca](https://www.onorca.dev/) installed and running (`orca status` reports ready)
- Claude Code logged in (running `claude` works) — other agents such as Codex work too
- git

---

## Step 0 — Create the Sample Project (3 min)

We'll build a tiny Python TODO app with bugs and gaps planted on purpose. Paste this straight into your terminal:

```bash
mkdir -p ~/orca-lab/todo-app && cd ~/orca-lab/todo-app && git init

cat > todo.py <<'PY'
"""A tiny TODO CLI. Intentionally buggy."""
import json, sys, os

DB = os.path.expanduser("~/.todo-lab.json")

def load():
    if not os.path.exists(DB):
        return []
    with open(DB) as f:
        return json.load(f)

def save(items):
    with open(DB, "w") as f:
        json.dump(items, f)

def add(text):
    items = load()
    items.append({"text": text, "done": False})
    save(items)

def done(index):
    items = load()
    items[index]["done"] = True      # Bug 1: 1-based input is not converted to 0-based, and there's no bounds check
    save(items)

def show():
    for i, item in enumerate(load()):
        mark = "x" if item["done"] else " "
        print(f"{i+1}. [{mark}] {item['text']}")

if __name__ == "__main__":
    cmd = sys.argv[1]                 # Bug 2: running with no arguments raises IndexError
    if cmd == "add":
        add(" ".join(sys.argv[2:]))
    elif cmd == "done":
        done(int(sys.argv[2]))
    elif cmd == "list":
        show()
PY

git add -A && git commit -m "todo app initial version (bugs included)"
```

> - We **deliberately** skip creating a `.gitignore` — a `__pycache__` directory will appear later,
>   which sets up the `worktree rm --force` lesson in Step 5. Just be careful not to sweep `.pyc` files
>   into your own commits.
> - To **redo** the lab, start over from Step 0 after `rm -rf ~/orca-lab/todo-app`.
>   Re-running on top of the existing directory would pile commits onto the previous run.

---

## Step 1 — Register the Project with Orca (2 min)

```bash
orca open                              # skip if already running
orca repo add --path ~/orca-lab/todo-app
orca repo list                         # verify registration
```

---

## Step 2 — Launch Three Tasks into Three Worktrees in Parallel (5 min)

Define three **independent** tasks. Independence is what lets them run in parallel without file conflicts.

> The lab was originally validated with Korean-language versions of these prompts; the English prompts below are faithful equivalents.

```bash
# Task A: fix the bug in the done command
orca worktree create --repo name:todo-app --name fix-done-bug --agent claude \
  --prompt "There is a bug in todo.py's done command. Users enter 1-based numbers but they are treated as 0-based, and there is no bounds check. Fix it, and also fix the IndexError that occurs when the script is run with no arguments so that it prints usage instead. Commit when done."
```

```bash
# Task B: add tests
orca worktree create --repo name:todo-app --name add-tests --agent claude \
  --prompt "Write pytest tests for todo.py in tests/test_todo.py. Isolate the DB file path using tmp_path. Run and refine the tests until they all pass (but do not modify todo.py itself). Make them runnable with a plain pytest command from the repo root (add a conftest.py if needed). Commit when done."
```

```bash
# Task C: write documentation
orca worktree create --repo name:todo-app --name write-readme --agent claude \
  --prompt "Read todo.py and write a README.md covering installation, usage, and examples. Do not modify todo.py. Commit when done."
```

> Branches are created as `<Orca-account-name>/<worktree-name>` (e.g. `gabin1234/fix-done-bug`).
> The prefix comes from **the account logged into Orca (your GitHub username)**, not from git's `user.name`;
> you can override it with the repo setting `gitUsername`.
> Without the trailing "commit when done" in the prompt, agents sometimes finish without committing, which costs you an extra manual step in Step 4.

> 💡 **Meta-prompting point**: each `--prompt` carries an exit condition ("until they all pass", "do not modify").
> Refining these templates is exactly what turning prompts into reusable assets means.

---

## Step 3 — Monitor (10 min)

While the agents are running, play air traffic controller:

```bash
orca worktree ps                       # whole picture at a glance
orca terminal list --worktree name:fix-done-bug --json   # find the terminal handle
orca terminal read --terminal <handle>   # read a specific agent's output
```

If an agent heads in the wrong direction, **intervene**:

```bash
orca terminal send --terminal <handle> --text "Write the tests in pytest style" --enter
```

If an agent is stalled waiting for input (e.g. a question), send a response the same way.

> ⚠️ Orca launches worktree agents with `--dangerously-skip-permissions` by default.
> That's a reasonable default for isolated worktrees, but it means agents run commands **without asking
> for approval** — all the more reason to scope your prompts precisely. (It's also why you'll almost
> never see an agent stall on a "permission approval" prompt.)

To wait for completion:

```bash
orca terminal wait --terminal <handle> --for tui-idle --timeout-ms 600000
```

> 💡 **Loop engineering point**: `read` is the feedback signal, `wait` is the exit condition, and `send` is divergence control (human intervention).

---

## Step 4 — Review and Merge (7 min)

Inspect each worktree's output as a diff. If the agents followed the Step 2 prompts, they have already
committed — so review **the committed branches**:

```bash
cd ~/orca-lab/todo-app
git branch -a                          # find the worktree branch names
git diff main...<fix-done-bug branch>  # repeat per branch
```

> `orca file open-changed --mode diff --worktree name:fix-done-bug` opens **uncommitted (git-changed)
> files only** in the Orca editor. If the agent has already committed, `No changed files.` is the
> expected output — this command is the tool for "peeking at work an agent hasn't committed yet."
> If an agent finished without committing, instruct it to commit via the terminal.

Once satisfied, merge from the main checkout:

```bash
git merge <fix-done-bug branch>
git merge <add-tests branch>
git merge <write-readme branch>
PYTHONPATH=. uvx pytest -q             # integration check (works even if the system python has no pytest)
python3 todo.py                        # verify the Bug 2 fix: does it print usage?
```

> Why `PYTHONPATH=.` is needed: `uvx pytest` runs pytest from an isolated venv, so the repo root is not
> automatically added to `sys.path`. Without it, you'd hit a collection error
> (`ModuleNotFoundError: No module named 'todo'`) before ever reaching the semantic conflict.
> (If Task B's agent satisfied the "runnable with plain pytest from the repo root" condition with a
> conftest.py, the run passes without it too — but it never hurts to include.)

> The three tasks touch different files, so the merges go through without git conflicts.

### ⚠️ Here comes the real lesson — semantic conflicts

The merge is clean, but **some tests will fail.** How many depends on what the agents produced, so it
varies run to run (rehearsal examples: 4 out of 10 in one run, 4 out of 9 in another).

Why: Task B's agent wrote its tests (as instructed) against the **buggy original**,
while Task A's agent fixed those bugs. The files don't overlap, so there's no git conflict —
but they **conflict semantically**. This is the core pitfall of parallel agent workflows.

- No git conflicts ≠ successful integration. **This is why running the full test suite after merging is non-negotiable.**
- Recovery: update the failing tests to match the fixed (correct) behavior and commit.
  You can do it by hand, or hand it to an agent in a fresh worktree.
- Prevention: change the Task B prompt to "write the tests against the **intended correct behavior** (1-based numbers, error message for invalid numbers), not the current implementation" — making the spec explicit in the prompt is exactly the value of meta-prompting.

---

## Step 5 — Clean Up (3 min)

```bash
orca worktree rm --worktree name:fix-done-bug
orca worktree rm --worktree name:add-tests
orca worktree rm --worktree name:write-readme
orca worktree list                     # verify cleanup
```

> - If untracked files like `__pycache__` are left behind, removal is refused — add `--force`.
> - Removing a worktree also has Orca clean up its branch **if it has been merged** (safe, since you've already merged).
>   Unmerged branches are not deleted automatically — they're kept with a warning ("local branch was kept").

To wipe every trace of the lab:

```bash
rm -f ~/.todo-lab.json                 # the DB file the app created in your home directory
rm -rf ~/orca-lab                      # the entire sample project
```

> The `todo-app` entry registered with Orca is harmless to leave in place.
> (The current CLI has no unregister command — remove it from the Orca app if you want it gone.)

---

## Completion Checklist

- [ ] Confirmed with `worktree ps` that three worktrees were running concurrently
- [ ] Read agent output and intervened using `terminal read`/`send`
- [ ] Reviewed the diffs and merged all three branches without conflicts
- [ ] Ran the tests yourself after merging to verify the integrated state
- [ ] Found the semantic conflict (tests written against the buggy behavior) and recovered
- [ ] Cleaned up the worktrees

## Challenges (Advanced)

1. **Review loop**: create a fourth worktree and tell it to "review the merged code and write improvement suggestions to REVIEW.md" (the review loop pattern from Part 2).
2. **Promote to orchestration**: define the same three tasks with `orca orchestration task-create` + `dispatch`, and add a decision gate (`gate-create`) as a human approval point before the merge.
3. **Automation**: use `orca automations create` to register a scheduled agent that "checks the repository every morning and leaves a report."
4. **Cost tiering**: apply the Qwen integration from Part 2 to route only lightweight work like Task C (documentation) to a low-cost backend.
