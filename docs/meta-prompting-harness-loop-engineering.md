# Meta Prompting · Harness Engineering · Loop Engineering

> AI coding (agentic coding) training material — separate from the graph computing module, this covers the
> three-part methodology for "putting AI to work" plus a token cost reduction strategy (Qwen subscription
> connected to Claude Code/Codex).

---

## 1. Meta Prompting

**Definition**: Instead of writing every prompt by hand, you **have the AI generate the prompt itself**.
You first ask the AI, "What would be the best prompt for this task?", then feed the resulting prompt back to the AI for execution — a two-stage structure.

### Core Idea
- **Stage 1 (Design)**: "I want to do X. Write the prompt that would accomplish this best — include the role, constraints, output format, and examples."
- **Stage 2 (Execution)**: Put the generated prompt into a new session (or a subagent) to perform the actual work.
- **Stage 3 (Improvement loop)**: If the result isn't satisfactory, go back up to the meta level — "The result came out like this; how should the prompt be fixed?" — and revise the prompt itself.

### Why Use It
- The AI fills in constraints and edge cases you would have missed, at the prompt-design stage.
- Prompts for recurring tasks become **assets** (save them to files → register them as slash commands/skills).
- In Claude Code: store them under `.claude/commands/` and `.claude/skills/` so the whole team can reuse them.

### Hands-on Example
```text
(Meta stage)
"Create a prompt template I can use every time I add a new API endpoint.
 Make sure it covers router registration, test writing, and documentation updates without omission."

(Execution stage)
Reuse the generated template repeatedly, swapping in only the endpoint name
```

---

## 2. Harness Engineering

**Definition**: Designing not the model itself but **the execution environment (harness) that wraps the model**.
The same model performs completely differently depending on which tools, context, permissions, and feedback loops you give it.

### Components of a Harness
| Component | Examples |
|---|---|
| Tools | File read/write, shell execution, browser, MCP servers |
| Context injection | CLAUDE.md, system prompts, memory, RAG |
| Permissions/guardrails | Allowed-command lists, sandboxing, approval flows |
| Verification loops | Automatic test runs, linting, build-result feedback |
| Subagent structure | Separate agents for exploration, implementation, and review |

### Core Principles
- **Suspect the harness before blaming the model**: Most failures happen not because "the model is dumb," but because the harness lacks the necessary information, tools, or means of verification.
- **Make things verifiable**: Quality jumps when the agent can run tests itself and check the results. From a harness perspective, the right design is not "write the code" but "write the code and keep fixing it until the tests pass."
- **Context is a budget**: Instead of dumping unnecessary files, a good harness delegates exploration to subagents and receives only the conclusions.

---

## 3. Loop Engineering

**Definition**: The technique of designing loops where the agent **repeats "execute → observe → fix" on its own**.
Rather than finishing with a single prompt-response, you design the termination conditions, feedback signals, and iteration cadence of a loop that runs until the goal state is reached.

### The Three Elements of a Loop
1. **Feedback signals**: Test results, compile errors, screenshots, logs — the evidence the agent uses to judge "is this going well right now?"
2. **Termination conditions**: Clear completion criteria such as "all tests pass," "no new findings for N consecutive iterations," or "build succeeds."
3. **Divergence prevention**: Maximum iteration counts, strategy changes when the same failure repeats, and conditions for escalating to a human.

### Practical Patterns
- **Test-driven loop**: Write a failing test first → iterate on the implementation until it passes.
- **Review loop**: A review agent critiques the implementation agent's output → changes are applied → re-review.
- **Long-running loop**: Wake up on a fixed schedule to check CI status and deployment status and take any needed action (Claude Code's `/loop`, cron schedules, etc.).

### How the Three Concepts Relate
```
Meta prompting       = designing WHAT to ask for (the prompt)
Harness engineering  = designing the ENVIRONMENT the AI works in
Loop engineering     = designing HOW it iterates and converges
```
Combined, they level you up from "giving one good instruction" to "**building a system that runs well on its own**."

---

## 4. Further Learning Resources

A short, curated list of primary sources that go deeper on each of the three disciplines.

### Meta Prompting / Prompt Engineering
| Resource | Type | Link |
|---|---|---|
| Prompt Engineering Overview — Anthropic Docs | Official docs | https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/overview |
| Anthropic Courses — Prompt Engineering Interactive Tutorial | Free course | https://github.com/anthropics/courses |

### Harness Engineering
| Resource | Type | Link |
|---|---|---|
| Building Effective Agents — Anthropic Engineering | Blog post | https://www.anthropic.com/engineering/building-effective-agents |
| Claude Code Best Practices — Anthropic Engineering | Blog post | https://www.anthropic.com/engineering/claude-code-best-practices |
| Claude Code Documentation | Official docs | https://docs.anthropic.com/en/docs/claude-code/overview |

### Loop Engineering
| Resource | Type | Link |
|---|---|---|
| Claude Code — Hooks, Automation & Headless Mode | Official docs | https://docs.anthropic.com/en/docs/claude-code/hooks |
| OpenAI Codex CLI | Open-source repo | https://github.com/openai/codex |

---

## 5. Token Cost Reduction Strategy — Qwen Subscription + Claude Code/Codex Integration

**Cost isn't a tax you pay for using agents more — it's a design variable you route around.**
Most agent cost problems aren't caused by expensive models; they're caused by the *absence of routing* —
sending every routine refactor, one-line fix, and doc update through the same premium model you reserve
for hard architecture decisions. That's like hiring a senior architect to change a CSS class.
Route the boilerplate tier to a cheap, fast, good-enough model and keep the premium model for the calls
that actually need it: **same harness, same workflow, a fraction of the token spend**. That is the core idea of this chapter.

Agentic coding consumes a lot of tokens, so costs grow quickly on pay-as-you-go API pricing.
One alternative strategy is to **purchase an Alibaba Qwen coding subscription and connect it as the backend for Claude Code or Codex CLI**.

### Path A — Direct Connection to Claude Code (Anthropic-Compatible Endpoint)

The Qwen subscription (Alibaba Cloud Model Studio's Coding Plan / Token Plan) provides an **Anthropic-compatible endpoint**,
so you can switch Claude Code's backend to Qwen with environment variables alone — no separate proxy needed.

```bash
export ANTHROPIC_BASE_URL="https://token-plan.ap-southeast-1.maas.aliyuncs.com/apps/anthropic"
export ANTHROPIC_API_KEY="sk-sp-xxxxx"   # must be a plan-specific key starting with sk-sp-
export ANTHROPIC_MODEL="qwen3.7-max"     # or qwen3-coder-plus, etc.
claude   # same Claude Code UI, but the model is now Qwen
```

**Common mistakes (causes of 401 errors)**:
- Using a workspace key starting with `sk-ws-` causes authentication failures or pay-as-you-go billing — you must use the **plan-specific `sk-sp-` key**.
- If no seat is assigned, the key still returns 401 — confirm "Standard Seat 1/1" status in the console before creating the key.
- Old `ANTHROPIC_*` variables lingering in your `.zshrc`/`.bashrc` frequently override the new settings.
- Verify in the Model Studio console that usage is billed against the Token Plan (and not leaking into pay-as-you-go).

### Path B — Routing via Claude Code Router (CCR)

[claude-code-router](https://github.com/musistudio/claude-code-router) is an open-source proxy that intercepts Claude Code's requests
and **routes them by role** to multiple backends. Unlike the direct connection (Path A),
it lets you assign different models per request type: `default / background / think / longContext / webSearch`.

```bash
npm install -g @anthropic-ai/claude-code @musistudio/claude-code-router
ccr code   # run Claude Code through the router
```

Example `~/.claude-code-router/config.json` (using the Qwen OAuth free quota):

```json
{
  "Providers": [{
    "name": "qwen",
    "api_base_url": "https://portal.qwen.ai/v1/chat/completions",
    "api_key": "<OAuth access token>",
    "models": ["qwen3-coder-plus"]
  }],
  "Router": {
    "default": "qwen,qwen3-coder-plus",
    "background": "qwen,qwen3-coder-plus",
    "think": "qwen,qwen3-coder-plus",
    "longContext": "qwen,qwen3-coder-plus"
  }
}
```

Note: The Qwen Code CLI's OAuth login grants a **free quota (60 requests/minute, 2,000/day)**,
so trying this path first before paying for a subscription is a reasonable approach.

### Path C — Codex CLI (OpenAI-Compatible Endpoint)

Codex CLI accepts OpenAI-compatible APIs, so register the same subscription's OpenAI-compatible base URL
(`https://token-plan.ap-southeast-1.maas.aliyuncs.com/compatible-mode/v1`)
as a custom provider in `config.toml`. Other tools like Cline and Cursor work the same way.

### Integration Tools at a Glance (CCR · CCH · cc-switch)

| Tool | Repository | Purpose |
|---|---|---|
| **CCR** (Claude Code Router) | [musistudio/claude-code-router](https://github.com/musistudio/claude-code-router) (36k+ ⭐) | Local proxy. Anthropic↔OpenAI format conversion plus per-request-type routing/fallback. **The standard for individual use** |
| **CCH** (Claude Code Hub) | [ding113/claude-code-hub](https://github.com/ding113/claude-code-hub) (3k+ ⭐) | Server-deployed multi-tenant proxy. Load balancing, per-user key/usage management — **for teams and organizations** |
| **cc-switch** | [farion1231/cc-switch](https://github.com/farion1231/cc-switch) | Desktop app for switching Claude Code/Codex provider configurations with a single click (CLI version: cc-switch-cli) |

In short: for solo use, **Path A (direct connection) or CCR** is enough; **CCH** fits organizational setups where multiple team members share a single subscription/key pool.

### A Sense of Pricing and Quotas (as of July 2026)

- The official [Qwen Coding Plan](https://www.alibabacloud.com/help/en/model-studio/coding-plan) is a **$50/month Pro** flat-rate subscription (first-month promotion: $15), with request quotas that reset on 5-hour, weekly, and monthly cycles (up to roughly 90,000 requests/month). Beyond the qwen family, it also includes third-party models such as Kimi and GLM, and officially supports 14+ tools including Claude Code and Codex. The entry tier (Lite, $10/month) stopped new sales in 2026, among other changes — **tier structures change often, so verify on the official page before paying**.
- The closest thing to a "roughly $200/year" annual plan is the qwencloud.com **Token Plan Standard at $195/year** mentioned in secondary sources, but this cannot be cross-verified in official documentation (official plans list monthly subscriptions only). Before paying, check the actual sales page yourself for pricing and whether an annual option exists.
- Caution: plan keys use the `sk-sp-` format and are limited to "interactive use within programming tools" (calling them from automation scripts or backend services violates the terms), and they are non-refundable.
- The `qwen3-coder-plus`, `qwen3-coder-next`, and `qwen3.x-plus` families land on this plan first.
- Key takeaway: **the harness (Claude Code/Codex) and the model (Anthropic/Qwen) are separable layers**. You can keep the same workflow while adjusting only the backend cost.

**References**:
- [Running Claude Code with free Qwen models (macOS guide)](https://medium.com/@hamzakh1010/how-to-run-claude-code-with-free-qwen-ai-models-on-macos-complete-setup-guide-7e15ae845e56)
- [Setting up Alibaba Cloud Qwen + Claude Code Token Plan and fixing 401 errors](https://aiopsschool.com/blog/how-to-use-alibaba-cloud-qwen-with-claude-code-using-the-30-token-plan-fix-api-key-billing-and-401-errors/)
- [Qwen coding plans in 2026, summarized](https://cheapestinference.com/blog/qwen-coding-plans/)
- [Introduction to Claude Code Router (GeekNews)](https://news.hada.io/topic?id=22288)
- [2026 AI coding plan comparison (Claude vs GLM vs Kimi vs Qwen)](https://codingplan.run/)

### Business Implications
- **Lower learning/experimentation costs**: A **two-track operation** becomes possible — run training, prototyping, and large batch jobs on a low-cost model subscription, and reserve high-performance models only for work that demands final quality.
- **Escape from vendor lock-in**: Once you think of the harness (Claude Code, Codex CLI) and the model (Anthropic, OpenAI, Qwen, ...) as separate layers, you can swap only the backend as model pricing/performance shifts.
- **Cost engineering for services**: When you later ship AI features in a product, the same structure (model abstraction via routers/proxies) lets you control costs while tuning quality — skills you build now transfer directly to the business.
