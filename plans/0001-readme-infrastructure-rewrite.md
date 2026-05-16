Status: implemented in working tree

# Plan 0001 — README Infrastructure Rewrite

## Context
`improvements.md` contains a captured rewrite direction for `README.md`: narrow the public README around private AI infrastructure, hardware, networking, operations, and vendored community integrations. The current README already includes much of that draft, but it needs a clean pass to remove rough duplicate structure, improve flow, and make the infrastructure positioning read as the source of truth.

## Approach
Rewrite `README.md` as a concise infrastructure-first product overview. Keep the private AI, quick start, core stack, infrastructure, WireGuard, AI hardware, repo structure, strategic pillars, non-goals, and community integrations sections. Remove persona/interface narrative from the README surface and leave that material in product planning docs.

## Tasks (precise todos)
1. **Clean the README narrative and section order** — consolidate intro, problem, executive summary, and quick start into a readable opening.
   - **Files touched** — `README.md`
   - **Dependencies** — none
   - **Owner-agent** — Cursor agent
2. **Rewrite infrastructure and hardware sections** — preserve the stack, network hardware, WireGuard topology, and machine spec details while removing duplicated separators and draft artifacts.
   - **Files touched** — `README.md`
   - **Dependencies** — task 1
   - **Owner-agent** — Cursor agent
3. **Tighten repo, principles, non-goals, and vendor integration sections** — keep operational details accurate and make the submodule guidance readable.
   - **Files touched** — `README.md`
   - **Dependencies** — task 2
   - **Owner-agent** — Cursor agent
4. **Verify the Markdown rewrite** — inspect the final file for broken code fences, duplicated headings, and leftover transcript language.
   - **Files touched** — `README.md`
   - **Dependencies** — task 3
   - **Owner-agent** — Cursor agent

## Critical files
- `README.md`
- `improvements.md` (source notes only; no planned edit)
- `plans/0001-readme-infrastructure-rewrite.md`

## Verification
- **Literal command** — `python3 - <<'PY'\nfrom pathlib import Path\ntext = Path('README.md').read_text()\nassert text.count('```') % 2 == 0\nassert 'Let me' not in text\nassert 'Actually,' not in text\nassert '\\n---\\n\\n---\\n' not in text\nprint('README markdown sanity checks passed')\nPY`
- **Expected output** — `README markdown sanity checks passed`
- **Literal command** — `git diff -- README.md`
- **Expected output** — A scoped documentation diff covering the README rewrite and required plan files, with no transcript artifacts and no unrelated code changes.

## Out of scope
- No backend, web, iOS, infrastructure, dependency, or deployment changes.
- No edits to `improvements.md` unless explicitly requested.
- No product vision expansion beyond the infrastructure-focused README rewrite.
