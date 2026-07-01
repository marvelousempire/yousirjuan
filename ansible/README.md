# Family Office IaC — Ansible

Infrastructure-as-Code for the family fleet: **Linux (DGX Spark)** and the **Mac fleet** builds, configs, and services. Everything we set up by hand should live here as a **repeatable, idempotent** play.

> Companion runbooks (human steps, one-offs): [`../docs/runbooks/`](../docs/runbooks/). When a runbook stabilizes, codify it as a role here.

## Layout

```
ansible/
├── ansible.cfg              # config (inventory path, ssh, no host-key prompts)
├── inventory/hosts.yml      # the fleet — DGX, Macs, NAS (verified 2026-07-01)
├── site.yml                 # top-level: run everything by group
├── playbooks/
│   ├── dgx-linux.yml        # DGX Spark (Ubuntu/DGX OS aarch64) build + configs
│   └── mac-fleet.yml        # Mac fleet (Apple Silicon + legacy) dev build
└── roles/
    ├── common/              # baseline every host
    ├── nas_10gbe_mount/     # the direct 10 GbE NAS mount (codifies the runbook)
    └── mac_dev/             # brew, ollama, model cache, fleet SSH
```

## Requirements

- Ansible ≥ 2.15 on the control node (a Mac or the DGX): `brew install ansible` / `pipx install ansible`.
- SSH reachability to each host (LAN + key — **no WireGuard needed** for home builds).
- Mac hosts: passwordless `sudo` for the privileged tasks, or run with `--ask-become-pass`.

## Usage

```bash
cd ansible
ansible-inventory --graph                      # see the fleet
ansible all -m ping                            # reachability

ansible-playbook playbooks/dgx-linux.yml       # build/configure the DGX
ansible-playbook playbooks/mac-fleet.yml       # build/configure the Macs
ansible-playbook site.yml                      # everything

# dry-run first (always):
ansible-playbook playbooks/dgx-linux.yml --check --diff
# limit to one host:
ansible-playbook playbooks/dgx-linux.yml --limit dgx
```

## Conventions

- **Idempotent** — re-running changes nothing when already in the desired state.
- **`--check --diff` before apply** — see what would change.
- **Secrets** never in git — use `ansible-vault` or host env; this repo ships no credentials.
- **One role per capability** — a hand-run runbook graduates into a role here.

## Status

Starter scaffold (2026-07-01). Codified so far: the **direct 10 GbE NAS mount** (`nas_10gbe_mount`). Linux + Mac build roles are real but intentionally minimal — grow them as we standardize each node.
