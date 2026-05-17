Status: proposed

# Plan 0002 — Payload Contractor Library

## Context

Avery defined **You-Sir Juan as the Payload Contractor**. Payloads are the
installable packages, kits, bundles, scripts, manifests, and deployment units
that turn platform intent into runnable infrastructure. All payloads should go
through You-Sir Juan instead of being scattered across Nephew, Automata,
Dockyard, or one-off repo folders.

The intended outcome is a first-class payloads library in `yousirjuan` that
becomes the canonical place to define, catalog, version, verify, and hand off
install packages.

## Tasks (precise todos)

1. **Define Payload Contractor doctrine** — add a short doctrine document that
   says You-Sir Juan owns payload packaging and that all install packages route
   through its payloads library.
   - **Files touched** — `docs/payload-contractor.md`
   - **Dependencies** — none
   - **Owner-agent** — Cursor agent

2. **Create payloads library scaffold** — create the canonical folder for
   reusable payload packages and define the package anatomy.
   - **Files touched** — `payloads/README.md`, `payloads/_template/README.md`,
     `payloads/_template/payload.json`
   - **Dependencies** — task 1
   - **Owner-agent** — Cursor agent

3. **Register install package routing in the README** — update the public repo
   overview so operators know repeated setup patterns become payloads in
   You-Sir Juan.
   - **Files touched** — `README.md`
   - **Dependencies** — tasks 1 and 2
   - **Owner-agent** — Cursor agent

4. **Update the operating lead sheet** — make payload selection an explicit
   phase before install execution, so installers and deployment scripts draw
   from the payload library.
   - **Files touched** — `OPERATING-SYSTEM-LEAD-SHEET.md`
   - **Dependencies** — tasks 1 and 2
   - **Owner-agent** — Cursor agent

5. **Add migration guidance for existing install packages** — document that
   existing scripts remain in place until migrated, but new install packages
   must be registered as payloads.
   - **Files touched** — `payloads/README.md`, `docs/payload-contractor.md`
   - **Dependencies** — tasks 1 through 4
   - **Owner-agent** — Cursor agent

## Critical files

- `plans/0002-payload-contractor-library.md`
- `plans/README.md`
- `docs/payload-contractor.md`
- `payloads/README.md`
- `payloads/_template/README.md`
- `payloads/_template/payload.json`
- `README.md`
- `OPERATING-SYSTEM-LEAD-SHEET.md`

## Verification

- **Literal command** — `python3 - <<'PY'
from pathlib import Path
required = [
    'docs/payload-contractor.md',
    'payloads/README.md',
    'payloads/_template/README.md',
    'payloads/_template/payload.json',
]
for path in required:
    assert Path(path).exists(), path
print('payload contractor files present')
PY`
- **Expected output** — `payload contractor files present`

- **Literal command** — `python3 -m json.tool payloads/_template/payload.json >/dev/null && echo 'payload template json ok'`
- **Expected output** — `payload template json ok`

- **Literal command** — `git diff -- README.md OPERATING-SYSTEM-LEAD-SHEET.md docs/payload-contractor.md payloads plans`
- **Expected output** — A scoped diff showing only the payload contractor doctrine,
  payload library scaffold, README/lead-sheet routing, and plan/index updates.

## Out of scope

- No migration of every existing installer/package in this plan.
- No new runtime installer engine.
- No deployment to GitHub or GitLab until the payload library scaffold is
  approved and implemented.
- No copying AI Skills Library content into You-Sir Juan; payloads may reference
  skills, but skills remain in the skills library.
