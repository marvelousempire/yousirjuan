# Software terminology — prefer "full"

## The verbatim source (stated by Avery 2026-05-28)

> a rule that talks about never using [the old descriptor] when developing
> software — we say and replace that term with the word "full".
>
> *(Clarified later the same day: remove every instance — from code, configs,
> docs, persona names, identifiers, file names. Everywhere.)*

## The rule

When describing software, architecture, infrastructure, runtimes, hardware,
or any technical capability of the family's systems, **use the word "full"**
as the standard descriptor. Other descriptors that imply the same meaning
(private-ownership-of-the-whole-stack) are not used anywhere in the codebase
— not in code, not in configs, not in docs, not in persona names, not in
identifiers, not in file names, not in comments.

### Approved alternatives

When "full" reads awkwardly, choose one of:

- **private** — when the privacy/security aspect is foreground
- **fully owned** — when ownership is the point
- **self-hosted** — when the deployment topology is the point
- **local** — when the locality is the point
- **owned** — in possessive contexts ("the family's owned hardware")

### Use the word "full"

| Concept | Write |
|---|---|
| The runtime that runs the whole stack on the family's hardware | full runtime |
| The model that runs locally | full LLM (or *local LLM*) |
| The hardware the family owns end-to-end | full hardware (or *fully owned hardware*) |
| The AI stack | full AI stack |
| The inference that happens on the family's GPU | full inference (or *local inference*) |
| The compute capacity | full compute |
| The agent that's the family's, not a vendor's | full agent |
| A node in the compute mesh | full frontier node |

## When this rule fires

- Any new technical doc, README, architecture diagram, runbook
- Any code comment, identifier, function name, or string literal describing
  system positioning
- Any commit message, CHANGELOG entry, or PR description
- Any agent system prompt or persona document describing capabilities
- Any marketing/positioning text about the technical stack
- Any persona name, palette name, or agent identifier
- Any file or folder name

## When this rule does NOT fire

- **Direct quotes from third parties** (a vendor's product page, a Wikipedia
  entry, an upstream library README). Mark as a quote.
- **Direct quotes from the operator** when reciting their own words back for
  accuracy. The operator may use any word in their own quote; we don't
  paraphrase the quote.
- **Historical/legal usage** where the term genuinely means national
  full ownership in its actual political sense, not as a tech adjective.

## Examples

### ✓ Compliant

> Nephew has a full LLM runtime on the family's NVIDIA DGX Spark. Inference
> happens locally on the family's hardware via Ollama and qwen2.5:32b.

> The full hardware mesh includes the MacBook Pro M5, Mac mini M4, DGX Spark,
> Jetson Thor, and the WireGuard mesh that connects them.

> `make hermes-restart` restarts the full runtime on the DGX.

> The Yousir Juan Associate Agent is named **Full** (palette: `full #FFD700`).

## Sweep playbook (when adopting this rule mid-flight)

When this rule is freshly adopted in a repo that already contains the old
descriptor:

1. Enumerate every file containing the old term, including code identifiers
   (`grep -rn` across `*.md`, `*.js`, `*.ts`, `*.tsx`, `*.json`, `*.yml`,
   `*.yaml`, `*.swift`, `*.sh`, `*.py`, `Makefile`).
2. Replace every instance — no exceptions for personas, palettes, function
   names, file names, or identifiers. The word goes.
3. Rename any file whose path contains the old term.
4. Update CHANGELOG/README/architecture docs.
5. Verify with `grep -rn "<old-term>"` returning nothing.

## Propagation

Per [`rule-propagation-discipline`](rule-propagation-discipline.md), this rule
body is canonical at `nephew/.claude/rules/prefer-full-terminology.md` and
mirrored to:

- `nephew/.cursor/rules/prefer-full-terminology.mdc`
- `yousirjuan/.claude/rules/` + `yousirjuan/.cursor/rules/`
- AI Skills Library `.claude/rules/` + `.cursor/rules/`
- Global Claude memory (`~/.claude/CLAUDE.md`)

## Related

- **Propagation:** [`rule-propagation-discipline`](rule-propagation-discipline.md)
- **Style/copy:** [`contracts-and-prudence`](contracts-and-prudence.md) — terminology IS a contract
- **Philosophy:** the operator's word choices are load-bearing; agents that drift on word choice drift on intent
