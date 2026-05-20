---
ledgerId: LEDGER-0010
title: Sandbox CLI generator — `make sandbox <tool>` for containerizing the unruly
status: in-progress
opened: 2026-05-20
closed: null
related-pains: []
related-tickets: [LEDGER-0007]
triggers:
  - manual-cli: `make -C ledger/LEDGER-0010-sandbox-cli-generator/playbooks sandbox tool=<name>`
---

# LEDGER-0010 — Sandbox CLI generator

## Ask

> "we should be able to use Grok CLI Beta there but maybe contained in a Docker container so it cant run wild? […] Build a `make sandbox <tool>` generator"

Build an infrastructure pattern for **containerizing untrusted or memory-hungry CLIs** so they can't damage the host. First user: Grok CLI Beta. Pattern reusable for any future tool that fits ADR-0001's containerization criteria.

## Outcome (Phase 1 in this PR)

A `Makefile` generator under `playbooks/` that produces a one-tool-per-directory layout:

```
ledger/LEDGER-0010-sandbox-cli-generator/playbooks/
├── Makefile                          ← the generator + dispatcher
├── _template/                        ← skeleton copied for each new sandbox
│   ├── docker-compose.yml.tmpl
│   ├── Dockerfile.tmpl
│   └── README.md.tmpl
├── grok-cli/                         ← first concrete sandbox
│   ├── docker-compose.yml
│   ├── Dockerfile
│   └── README.md
└── (future sandboxes: n8n, etc.)
```

Operator commands:

```bash
make -C ledger/LEDGER-0010-sandbox-cli-generator/playbooks sandbox tool=grok-cli   # one-time scaffold
make -C ledger/LEDGER-0010-sandbox-cli-generator/playbooks build  tool=grok-cli    # docker build
make -C ledger/LEDGER-0010-sandbox-cli-generator/playbooks run    tool=grok-cli    # interactive shell
make -C ledger/LEDGER-0010-sandbox-cli-generator/playbooks stop   tool=grok-cli
make -C ledger/LEDGER-0010-sandbox-cli-generator/playbooks list                    # all sandboxes + their state
```

Each sandbox gets:

- Its own Dockerfile (lowest-priv user, single-tool image)
- Its own `docker-compose.yml` with a dedicated network (`sandbox-net-<tool>`)
- A scoped workspace mount (`~/sandbox-workspaces/<tool>/`) — the only host filesystem the tool sees
- Memory cap (`mem_limit: 2g` default; configurable per tool)
- No bind-mount to the operator's home dir, dotfiles, ssh keys, etc.

## ADR alignment

This ticket is the concrete implementation of **ADR-0001 Section 3**: "Selective Docker for the unruly." Each new sandbox needs to fit ADR-0001's criteria (untrusted by default OR native-deps hell OR memory-bounded target).

## Runbooks (planned)

- `01-sandbox-pattern.md` — what fits in a sandbox vs what doesn't; ADR-0001 cross-link
- `02-adding-a-new-tool.md` — operator runbook for `make sandbox tool=<name>`
- `03-grok-cli-first-use.md` — getting Grok CLI Beta running in its sandbox

## Playbooks

- `Makefile` — the generator + dispatcher (`sandbox`, `build`, `run`, `stop`, `list`)
- `_template/docker-compose.yml.tmpl` — base compose with network + mem cap
- `_template/Dockerfile.tmpl` — base image pattern (non-root user)
- `grok-cli/docker-compose.yml` — first concrete sandbox
- `grok-cli/Dockerfile` — Grok CLI Beta install
- `grok-cli/README.md` — invocation + auth setup

## Phase 1 ships in this PR

- The Makefile generator + dispatcher
- The `_template/` skeleton
- The `grok-cli/` directory as the first concrete use

Phase 2 (sibling PRs/LEDGER entries): more sandboxes as new tools come up. The Makefile makes that ~5 min of operator work each time, by design.

## Verification (Phase 1)

```bash
make -C ledger/LEDGER-0010-sandbox-cli-generator/playbooks list                  # shows grok-cli
make -C ledger/LEDGER-0010-sandbox-cli-generator/playbooks build tool=grok-cli   # builds image
make -C ledger/LEDGER-0010-sandbox-cli-generator/playbooks run   tool=grok-cli   # drops into shell
# inside the container:
grok --version                                                                    # CLI present
ls ~/workspace                                                                    # only sees the scoped mount
ls /                                                                              # no host files visible
exit
```

## Undo

Removing a sandbox is `rm -rf` the tool's subdirectory. The Docker image can be removed with `docker rmi sandbox-<tool>:latest`.

To undo this whole ticket: remove `ledger/LEDGER-0010-sandbox-cli-generator/`. No other repo state touched.

## Cross-references

- ADR-0001 — the architectural decision this implements.
- LEDGER-0007 runbook 05 — n8n OOM motivated the "memory-bounded target" criterion.
- Future: a sandbox for `n8n` will land here once we're ready to migrate it off the VPS-host install.
