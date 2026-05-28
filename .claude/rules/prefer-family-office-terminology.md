# Software terminology — prefer "Family Office"

## The verbatim source (stated by Avery 2026-05-28)

> we change it all from Full to Family Office. So no sovereign — we say
> Family Office instead.

History: the operator first asked for the old descriptor to be replaced with
"full". Same day, on seeing the result, they clarified: the replacement is
**"Family Office"**, not "full". This rule reflects that final word.

## The rule

When describing software, architecture, infrastructure, runtimes, hardware,
or any technical capability of the family's systems, **use the phrase
"Family Office"** as the standard descriptor.

The older descriptor (a word for private-ownership-of-the-whole-stack that
the operator has retired) is not used anywhere in the codebase. The
intermediate placeholder "full" — which was used during the first sweep —
is also retired for positioning purposes; "full" stays only when it carries
its ordinary English meaning ("complete", "entire", "filled"), not when it
describes the family's stack.

### Examples — use "Family Office"

| Concept | Write |
|---|---|
| The runtime that runs the whole stack on the family's hardware | Family Office runtime |
| The model that runs locally | Family Office LLM (or *local LLM*) |
| The hardware the family owns end-to-end | Family Office hardware |
| The AI stack | Family Office AI stack |
| Inference on the family's GPU | Family Office inference (or *local inference*) |
| The compute capacity | Family Office compute |
| The agent that's the family's, not a vendor's | Family Office agent |
| A node in the compute mesh | Family Office frontier node |
| The architectural principle for keeping public APIs outside | The Family Office Sandwich |

### "full" is still allowed when it means "complete"

The word **"full" remains valid English** when it carries its ordinary
meaning of completeness:

- "full path" / "full text" / "full coverage"
- "Full Intelligence & Anticipation" (Nephew Trust Protocol point 4 — means *complete* intelligence)
- "full Docker stack" (means complete)
- "full disclosure"

It is only retired as a **stack-positioning descriptor** — anywhere it used to
mean "what we own end-to-end" gets replaced with "Family Office".

## When this rule fires

- Any new technical doc, README, architecture diagram, runbook
- Any code comment, identifier, function name, or string literal describing
  system positioning
- Any commit message, CHANGELOG entry, or PR description
- Any agent system prompt or persona document describing capabilities
- Any persona name, palette name, or agent identifier that previously used
  the retired word

## When this rule does NOT fire

- Quotes of the operator's prior speech (when they used the retired word,
  preserve it inside the quote and add a footnote/clarifier if needed)
- Quotes of third parties (vendor pages, upstream READMEs)
- Ordinary English "full" that means "complete" (see the "still allowed"
  section above)

## Sweep playbook

When this rule is freshly adopted in a repo that already contains the
retired descriptor or its earlier replacement:

1. Enumerate every file containing `Family Office runtime`, `Family Office LLM`, `full
   hardware`, `Family Office AI stack`, `Family Office inference`, `Family Office compute`, `Family Office agent`,
   `full frontier`, `Family Office positioning`, the retired older word, or any
   variant.
2. Replace each instance with the "Family Office" equivalent from the table
   above.
3. Rename any file whose path encodes the descriptor.
4. Rename any code identifier (palette/persona/manifest key) that uses the
   descriptor; update every consumer.
5. Update CHANGELOG/README/architecture docs.
6. Verify with `grep -rn "<old-term>"` returning zero for the positioning
   sense.

## Propagation

Per [`rule-propagation-discipline`](rule-propagation-discipline.md), this rule
body is canonical at `nephew/.claude/rules/prefer-family-office-terminology.md`
and mirrored to:

- `nephew/.cursor/rules/prefer-family-office-terminology.mdc`
- `yousirjuan/.claude/rules/` + `yousirjuan/.cursor/rules/`
- AI Skills Library `.claude/rules/` + `.cursor/rules/`
- Global Claude memory (`~/.claude/CLAUDE.md`)

## Related

- **Propagation:** [`rule-propagation-discipline`](rule-propagation-discipline.md)
- **Style/copy:** [`contracts-and-prudence`](contracts-and-prudence.md) — terminology IS a contract
- **Philosophy:** the operator's word choices are load-bearing; agents that drift on word choice drift on intent
