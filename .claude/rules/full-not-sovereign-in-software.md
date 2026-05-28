# Software terminology — use "full" not "sovereign"

## The verbatim source (stated by Avery 2026-05-28)

> we need to remember — Nephew has a rule (i think yousirjuan has that rule in
> fact but nephew needs it too — all need it.) a rule that talks ablout never
> using sovereigned when developing software — we say and replace that term
> with the word "full".

## The rule

When describing software, architecture, infrastructure, runtimes, hardware
configurations, or any technical capability of the family's systems, **use
the word "full" instead of "sovereign"** (or one of the approved alternatives
below when "full" doesn't read cleanly).

| Don't write | Write instead |
|---|---|
| sovereign runtime | full runtime |
| sovereign LLM | full LLM (or *fully owned LLM* / *local LLM*) |
| sovereign hardware | full hardware (or *fully owned hardware*) |
| sovereign AI stack | full AI stack |
| sovereign inference | full inference (or *local inference*) |
| sovereign compute | full compute |
| sovereign agent | full agent |
| sovereign positioning | full positioning |
| sovereign frontier node | full frontier node |
| running on sovereign hardware | running on fully owned hardware |

**Approved alternatives** when "full" reads awkwardly:
- **private** (when the security/privacy aspect is foreground)
- **fully owned** (when ownership is the point)
- **self-hosted** (when the deployment topology is the point)
- **local** (when the locality is the point)
- **owned** (in possessive contexts like "the family's owned hardware")

## Why

The operator does not want "sovereign" used as a software descriptor. It is a
permanent style preference for every doc, every commit message, every README
line, every prompt the agent writes about the family's systems.

## When this rule fires

- Any new technical doc, README, architecture diagram, runbook
- Any code comment describing system positioning
- Any commit message, CHANGELOG entry, or PR description discussing
  infrastructure
- Any agent system prompt or persona document describing capabilities
- Any marketing/positioning text about the technical stack

## When this rule does NOT fire

- **Proper nouns** that already contain "Sovereign" as a name (e.g. the
  Associate Agent persona named `Sovereign` in yousirjuan — that is the
  person's chosen name, not a technical descriptor).
- **Direct quotes from third parties** (a vendor's product page, a
  Wikipedia entry, an upstream library README). When quoting, mark it as
  a quote.
- **Direct quotes from the operator** when reciting their own words back
  for accuracy.
- **Historical/legal usage** where the term means national sovereignty in
  its actual political sense, not as a tech adjective.

## Examples

### ✓ Compliant

> Nephew has a full LLM runtime on the family's NVIDIA DGX Spark. Inference
> happens locally on the family's hardware via Ollama and qwen2.5:32b.

> The full hardware mesh includes the MacBook Pro M5, Mac mini M4, DGX Spark,
> Jetson Thor, and the WireGuard mesh that connects them.

> `make hermes-restart` restarts the full runtime on the DGX.

### ✗ Violation

> Nephew has a sovereign LLM runtime on the family's NVIDIA DGX Spark.
> *(Use "full" instead.)*

> The sovereign hardware mesh includes...
> *(Use "full hardware mesh" instead.)*

> Running on sovereign hardware means no data leaves the network.
> *(Use "fully owned hardware" or "the family's own hardware" instead.)*

### ✗ Violation — file naming

`orientation/chapter-01-what-nephew-is/06-sovereign-and-absorbing.md`
*(Should be `06-full-and-absorbing.md`.)*

## Sweep playbook (when adopting this rule mid-flight)

When this rule is freshly adopted in a repo that already contains violations:

1. `grep -rl "sovereign" --include="*.md" --include="*.js" --include="*.ts" --include="*.py" .` to enumerate files
2. Skip: proper nouns (Sovereign Associate Agent), direct quotes, vendor names
3. Sweep each file with the replacement table above
4. Rename any file whose path contains `sovereign`
5. Update the CHANGELOG/README/architecture docs that introduced the term

## Propagation

Per [`rule-propagation-discipline`](rule-propagation-discipline.md), this rule
body is canonical at `nephew/.claude/rules/full-not-sovereign-in-software.md`
and mirrored to:

- `nephew/.cursor/rules/full-not-sovereign-in-software.mdc`
- `yousirjuan/.claude/rules/` + `yousirjuan/.cursor/rules/`
- AI Skills Library `.claude/rules/` + `.cursor/rules/`
- Global Claude memory (`~/.claude/CLAUDE.md`)

## Related

- **Propagation:** [`rule-propagation-discipline`](rule-propagation-discipline.md)
- **Style/copy:** [`contracts-and-prudence`](contracts-and-prudence.md) — terminology IS a contract
- **Philosophy:** the operator's word choices are load-bearing; agents that drift on word choice drift on intent
