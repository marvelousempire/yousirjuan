# Changelog

All notable changes to **yousirjuan** ship here. Format follows the convention in [`.claude/rules/changelog-and-versioning.md`](../.claude/rules/changelog-and-versioning.md):

```
## [0.x.y] — YYYY-MM-DD HH:MM:SS Eastern · *short tagline*
```

Eastern time stamped to the second using `TZ=America/New_York date '+%Y-%m-%d %H:%M:%S'`. Newest entries first.

---

---

---

---

## [0.7.21] — 2026-07-08 11:03:59 Eastern · *OWC TB5 cable purchase record + benchmark-cassette plan*

### Added
- `data/hardware-spec-registry.json` — `owc-tb5-cables` entry: OWC 0.3m Thunderbolt 5 cable
  (80/120Gb/s, 240W), qty 6, ASIN `B0DH7VN49M`, confirmed via SME Amazon order history
  (order `111-3241992-3391448`, part of the DGX Spark bundle). A second/"long" TB5 cable
  the operator recalled buying was **not found** in indexed purchase data — noted explicitly
  in the entry rather than guessed.
- `plans/0007-benchmark-cassettes-hardware-console.md` — proposes extending the You-Sir Juan
  Hardware Console's existing receipt-backed benchmark model (`yousirjuan-console` cassette)
  with new categories (cable throughput, drive speed, network link) so physical hardware like
  the TB5 cable above can carry a measured-performance receipt, not just a purchase record.

## [0.7.20] — 2026-07-01 08:58:07 Eastern · *NVIDIA DGX Spark official vendor spec sheet*

### Added
- `hardware/dgx-spark-official-spec.md` — full NVIDIA product-page + GTC25 datasheet table (SKU 940-54242-0000, acoustics, power) with live `nephew-spark` reconciliation.

### Changed
- `docs/setup/32-hardware-full-spec-sheet.md` — §2.0 official vendor specs; §2.1–2.4 reconcile vendor vs live (ConnectX-7 vs Realtek, 128 vs ~122 GB).
- `data/hardware-spec-registry.json` — `vendor_official` + `vendor_urls` on `dgx-spark`.
- `docs/hardware/dgx-spark-frontier-node.md` · `docs/setup/01-hardware.md` — link vendor deep dive.

## [0.7.19] — 2026-07-01 08:49:05 Eastern · *SME purchase proof wired into hardware registry*

### Added
- `data/hardware-spec-registry.json` **schema v2** — `commerce_provenance` (SME Amazon 863 / eBay 0) + per-device `purchases[]` (ASIN, order date, USD).
- `docs/setup/32-hardware-full-spec-sheet.md` **§13** — SME Family Inventory purchase table + refresh SQL; §10 drive table provenance column.

### Changed
- `hardware/ugreen-dxp6800-pro-spec.md` — purchases table; Pool 2 HDD confirmed **IronWolf Pro ST4000NT001** via SME.
- `docs/setup/01-hardware.md` — link SME `/orders` + ch. 32 §13.

## [0.7.18] — 2026-07-01 14:00:00 Eastern · *Full hardware spec sheet (ch. 32)*

### Added
- `docs/setup/32-hardware-full-spec-sheet.md` — ports, link speeds, drives, cables, docks, network gear (UGREEN DXP6800 Pro vendor + installed pools, DGX live probe, Mac fleet, cable matrix).
- `hardware/ugreen-dxp6800-pro-spec.md` — NAS-only deep dive (UGOS, not Synology).
- `data/hardware-spec-registry.json` — machine-readable companion registry.

### Changed
- `docs/setup/01-hardware.md` — link to ch. 32; DGX↔NAS **10 GbE storage path live** (reconcile vs 1 GbE USB Trusted LAN leg).
- `docs/setup/README.md` — chapter 32 index row.
- `hardware/ugreen-nas-code-vault.md` — header points at live DXP6800 Pro + ch. 32 (vault plan text retained).

## [0.7.17] — 2026-06-26 09:30:00 Eastern · *Super Rick voice stack full undressing (ch. 30)*

### Added
- `docs/setup/30-voice-stack-full-undressing.md` — complete Family Office voice configuration: services, models, ports, tweaks, Presence orb stack.
- Setup index row for chapter 30; cross-links from `ai-skills/tts-and-speech-systems.md` and `model-to-hardware-mapping.md`.

## [0.7.16] — 2026-06-25 11:09:38 Eastern · *Mac fleet Bonjour file sharing — LEDGER-0036*

### Added
- `ledger/LEDGER-0036-mac-fleet-bonjour-file-sharing/` — full session journal, 6 runbooks, 7 playbooks
  (nephew-spark mDNS fix, admin-only SMB, hostname mounts, onemac/twomac bootstrap).
- `pain-journal/PAIN-0011-finder-shows-ip-not-bonjour-name.md` — IP vs Bonjour duplicate rows in Finder Network.
- `pain-journal/PAIN-0012-dgx-docker-pollutes-mdns.md` — Docker bridges breaking `nephew-spark.local`.

### Changed
- `ledger/README.md` — index row + next number `LEDGER-0037`.
- `docs/Feature Ledger.md` — platform row for fleet LAN file sharing.
- `HANDOFF.md` — Day entry for 2026-06-25 fivemac mesh session.

> **What to look for:** `bash ledger/LEDGER-0036-mac-fleet-bonjour-file-sharing/playbooks/install-from-fivemac.sh`
> then `mount | grep nephew-spark.local` (no `@192.168.10.205` in mount URLs).

---

## [0.7.15] — 2026-06-17 13:50:00 Eastern · *Family SSO receipt + LEDGER-0035 (merge PR #1)*

### Added
- `ledger/LEDGER-0035-family-sso-infra-receipt/` — triage + recover runbooks + `sso-smoke.sh` replay.
- `plans/0006-nephew-platform-sync-receipt.md` — standing sync table when Nephew ships platform plans.
- `docs/agent-pastes/family-sso-operator-context.md` — short paste for SSO debugging across repos.

### Changed
- `docs/setup/26-family-sso-and-door-tickets.md` — expanded hub sign-in, door-ticket handoff, recovery (host-only local cookies).
- `docs/setup/17-agents-fleet-bishop-cloak.md` — Bishop-optional boot (0195) + factory player (0198) tables.
- `docs/setup/12-pockit-non-vanilla-surfaces.md` — living re-skin section.
- `docs/setup/08-daily-operator-workflows.md` — `POCKIT_LOCAL_ONLY`, SSO smoke.
- `docs/Feature Ledger.md` — SSO, Bishop boot, factory player rows.

---

## [0.7.14] — 2026-06-16 11:08:05 Eastern · *RL-0051 agent executes don't delegate*

### Added
- `.claude/rules/agent-executes-dont-delegate.md` + `.cursor/rules/agent-executes-dont-delegate.mdc`
  (always-on) — operator standing order: execute safe work; Boss Moves only for sudo/secrets/browser.

### Changed
- `rules/GLOBAL-RULES-FOR-USING-NEPHEW.md` Rule 1 re-affirmed with 2026-06-16 verbatim.
- `AGENTS.md`, `CLAUDE.md`, agent paste, `forge-push-always` — cross-links to RL-0051.

---
## [0.7.13] — 2026-06-15 18:30:00 Eastern · *Cassette agent bridge + Nephew voice sync*

### Added
- `docs/setup/25-cassette-update-agent-bridge.md` — YSJ ↔ Nephew routing for Update the Cassette,
  elevations map, agent attach bundle, post-Nephew maintenance ritual.
- `docs/agent-pastes/README.md` + `infrastructure-operator-context.md` — infrastructure agent
  paste; links to Nephew `cassette-update-context.md` without duplicating SOP.

### Changed
- `docs/setup/README.md` — chapter 25 index + agent paste pointers.
- `docs/setup/08-daily-operator-workflows.md` — expanded cassette ritual with cross-repo steps.
- `docs/setup/05-nephew-orchestration.md` — agent paste attach table.
- `docs/setup/11-voice-parakeet-premium-stack.md` — v1.79.42 `CHECK=voice` + schema note.
- `docs/setup/15-doors-cassettes-pockit-navigation.md` — Pattern E voice pad + ch. 25 link.
- `AGENTS.md` — agent-pastes surface + cross-repo routing row.

## [0.7.12] — 2026-06-16 10:15:00 Eastern · *Master blueprint consolidation*

### Changed
- `docs/setup/00-system-blueprint-audit-2026-06.md` — full consolidated system blueprint
  (voice, zero-trust Caddy, Redis Sentinel, devices, DNS, WireGuard roadmap).

## [0.7.11] — 2026-06-16 10:00:00 Eastern · *Forge sync without GitHub SSH*

### Added
- `artifacts/forge-sync-core.txt` — timer scope (public repos: yousirjuan, ai-skills-library).
- `scripts/forge-pull-on-gitea.sh`, `forge-pull-on-gitea-core.sh` — DGX bare-repo GitHub→Gitea pull via HTTPS.
- `scripts/forge-sync-core.sh`, `make forge-sync-core`.

### Fixed
- `forge-sync.sh` — Gitea-first bootstrap; GitHub HTTPS fallback; optional DGX server pull.
- `forge-sync-all.sh` — defaults to core list (not ~90 LEDGER repos without GitHub auth).
- `forge-status.sh` — HTTPS origin SHA when Mac lacks GitHub SSH.
- Mac LaunchAgent + DGX systemd timer — core repos only; DGX uses server-side pull.

## [0.7.10] — 2026-06-16 09:50:00 Eastern · *Standing order: agents always forge-push*

### Added
- `.cursor/rules/forge-push-always.mdc` + `.claude/rules/forge-push-always.md` — operator
  directive: Nephew always runs `make forge-push` before reporting done; never delegate sync.
- `AGENTS.md` universal rule #10 + forge-push row in task table.

## [0.7.9] — 2026-06-16 09:45:00 Eastern · *Full forge sync automation + Gitea Actions*

### Added
- `Makefile` — `verify`, `forge-push`, `forge-sync`, `forge-status`, `setup-forge-remotes`.
- `scripts/forge-sync.sh`, `forge-push.sh`, `forge-sync-all.sh`, `forge-status.sh`,
  `setup-forge-remotes.sh`, `yousirjuan-verify.mjs`.
- `scripts/install-dgx-forge-sync-timer.sh`, `install-mac-forge-sync-timer.sh`.
- `scripts/gitea-enable-actions.sh`, `deploy/gitea/act-runner-compose.yml`.
- `.gitea/workflows/verify.yml` — CI on self-hosted runner (not GitHub Actions).
- `docs/setup/23-forge-sync-automation.md` — full automation chapter.

### Fixed
- Canonical remote: **`marvelousempire/yousirjuan`** on Gitea (not `avery/yousirjuan`).
- `avery/yousirjuan` archived in Gitea DB with deprecation description.
- Gitea Actions enabled on DGX; `gitea-act-runner` registered (`dgx-spark-family-office`).
- Forge-sync timers: Mac LaunchAgent + DGX user systemd (every 5 min).

> **Operator:** `make forge-push` after edits. Enterprise GitHub pushes auto-reconcile within 5 min.

## [0.7.8] — 2026-06-16 09:30:00 Eastern · *Gitea branch hygiene + doc era reconciliation*

### Added
- `docs/setup/22-doc-era-reconciliation.md` — live topology vs superseded whitepapers/branches.

### Fixed
- Gitea `avery/yousirjuan` default branch set to **`main`** (was `docs/operator-setup-master-guide`).
- Bare repo `HEAD` pointed at `main`.
- Deleted stale branches on Gitea + GitHub: `docs/operator-setup-master-guide`,
  `voice-security-audit-2026-06`, `plan/border-control-wg`.

## [0.7.7] — 2026-06-15 19:30:00 Eastern · *Reconcile Gitea master with GitHub enterprise audit*

### Added (from GitHub branch `voice-security-audit-2026-06`)
- `docs/setup/00-system-blueprint-audit-2026-06.md` — enterprise audit index.
- `docs/setup/19-zero-trust-caddy-doors.md`, `20-mobile-surfaces-ios17.md`,
  `21-redis-persistence.md`, `24-apple-neural-engine-voice-optimization.md`.
- `infrastructure/redis/` and `infrastructure/caddy/` compose stubs.

### Fixed
- Restored full `docs/setup/README.md` and `11-voice-parakeet-premium-stack.md` after
  enterprise branch had replaced them with stubs during fast-forward.
- README now documents **Gitea = master**, GitHub = enterprise agent mirror lane.
- Integrated audit chapters into 24-chapter index without losing ch. 1–18 content.

> **Sync rule:** merge enterprise GitHub work to **Gitea `main` first**, then mirror to GitHub.

## [0.7.6] — 2026-06-15 18:45:00 Eastern · *Doors, RAG fabric, agents, WG/Matrix/Gitea with intents*

### Added
- `docs/setup/15-doors-cassettes-pockit-navigation.md` — Pockit as family desktop,
  door mechanism, `make doors` vs `make door`, full-page cassette URLs, embed vs tape types.
- `docs/setup/16-knowledge-fabric-rag-quantization.md` — Brain A/B, bge-m3/reranker,
  AWQ/FP8 tiers, KB cassettes, ingest→retrieve pipeline, agent checklist.
- `docs/setup/17-agents-fleet-bishop-cloak.md` — chain of command, Bishop factory,
  fleet passports, CLOAK MCP 28 tools, Trust Protocol, Visual vs Jarvis.
- `docs/setup/18-wireguard-matrix-nas-gitea-why.md` — WG mesh to DGX/NAS, Protectli path,
  Matrix/Element family chat, NAS Docker tier (Plan 0197), Gitea vs GitLab vs GitHub reasons.
- Intent blocks added to chapters 2, 5, 6, 7; README expanded to 18 chapters.

> **What to look for:** Every section now leads with **Intents** (the why). Start at ch. 15
> for doors/Pockit; ch. 16 for RAG; ch. 17 for Bishop/agents; ch. 18 for WG + forge reasons.

## [0.7.5] — 2026-06-15 16:30:00 Eastern · *Physical topology, Protectli, Historia memory chapters*

### Added
- `docs/setup/13-physical-topology-protectli.md` — live `.10` LAN cabling, complete device
  inventory, 10GbE DGX↔NAS, VLAN plan, Protectli VP6670 ten-step migration, Plan 0197
  DGX-vs-NAS tiers, doc-era reconciliation (stale `.8.x` warning).
- `docs/setup/14-historia-and-operator-memory.md` — sovereign vault paths, Qdrant
  collections, Grok pump, LaunchAgents, where chat history lives vs setup docs.
- Expanded `01-hardware.md` — FIVEMAC/ONEMAC, Protectli arriving, Comet KVM, desk docks.
- Setup README — gaps table, chapters 13–14 index, privacy rule clarified for LAN docs.

> **What to look for:** Protectli arrives → execute checklist in chapter 13 before
> retiring MT6000 as router. For "what did we say in chat," use chapter 14 + Historia vault.

## [0.7.4] — 2026-06-15 16:05:00 Eastern · *Setup docs — machine comms, M5 edge, premium voice, Pockit synthesis*

### Added
- `docs/setup/09-talking-to-your-machines.md` — SSH fleet, doors, tower-api, Visual vs Jarvis,
  Cursor/MCP, Apple hands-on, async messaging.
- `docs/setup/10-m5-max-sovereign-edge.md` — Nephew Max M5 edge daemon chain, hybrid routing,
  Obsidian golden profile, failover.
- `docs/setup/11-voice-parakeet-premium-stack.md` — Kokoro demoted to fallback; Holler premium
  on M5; F5/Riva on DGX; Parakeet cassette; reboot-safe voice (Plans 0201/0202).
- `docs/setup/12-pockit-non-vanilla-surfaces.md` — suite bar, Comet motion, cassette discipline,
  Jarvis Sovereign hub, native Pockit.app.

> **What to look for:** Chapter 11 documents the intentional move off vanilla Kokoro TTS to
> Holler (Grok-class premium) — the synthesis story for non-vanilla sovereign voice.

## [0.7.3] — 2026-06-15 11:55:00 Eastern · *Public-safe operator setup master doc (`docs/setup/`)*

### Added
- `docs/setup/README.md` — master index for the complete Family Office system (hardware +
  network + software + Nephew + git/deploy + daily workflows).
- Chapters `01-hardware.md` through `08-daily-operator-workflows.md` — consolidated,
  GitHub-safe reference with no LAN addresses, port numbers, domain names, or operator PII.
- README link block pointing agents and operators to `docs/setup/`.

> **What to look for:** Open `docs/setup/README.md` before briefing another model on the full
> stack. Use `ledger/` and nephew `docs/infrastructure/` for live ports and peers — not this tree.

## [0.7.2] — 2026-06-09 14:00:00 Eastern · *§7 microscopic operator detail (OpenWrt, Synapse, Matrix bot, Protectli)*

### Added
- `docs/home-network-full-architecture-report.md` **§7** — LuCI VLAN paths, uci CLI, fw4/nft zone
  rules, Wi-Fi SSID binding, Synapse + Element + AppService snippets, Docker Compose skeleton,
  Protectli migration checklist. §2 VLAN table aligned to live `.10` Trusted + `.11` IoT.
- Cross-link to `marvelousempire/nephew/infra/README.md` (Plan 0162 DGX IaC).

> **What to look for:** In §7.1, export a GL.iNet backup before VLAN lab. After §7.2, run
> `glmt6000-firewall-persist.sh` so VPS→DGX forwarding survives fw4. Matrix snippets use
> mesh-only `matrix.jailynmarvin.com` — no public A record. DGX fleet IaC: `make infra-verify-dgx` in nephew repo.

## [0.7.1] — 2026-06-09 12:00:00 Eastern · *Full home-network architecture report (MT6000, Matrix, Protectli)*

### Added
- `docs/home-network-full-architecture-report.md` — operator-confirmed microscopic briefing for
  agents: current MT6000 + Brume dumb-switch topology, immediate VLAN/firewall plan, Matrix +
  Element on UGREEN NAS, DGX-backed Matrix AppService bot, Protectli VP6670 future state, privacy
  goals. Portable copy in `marvelousempire/nephew/docs/`.
- Supersession banner on `docs/hardware/network-architecture.md`; cross-link from
  `docs/whitepaper-hardware-network.md`.

> **What to look for:** Open `docs/home-network-full-architecture-report.md` and confirm §1 matches
> live cabling (Verizon passthrough → MT6000 WAN; Brume 3 as switch). Compare §2 VLAN targets to
> the flat `192.168.10.0/24` LAN before applying OpenWrt changes.

## [0.7.0] — 2026-06-02 16:55:50 Eastern · *Plan 0004 Phase 1 — domain generator (TLD is one variable)*

### Added
- framework.config.json (single source of truth: tld + org + edge_ip + cassettes with exposure tiers) and scripts/render-framework.mjs, which generates every edge vhost + DNS record + cert SAN from the TLD. Proven: changing tld regenerates the whole edge (the change-the-TLD test). No live edge change yet (Phase 2). Foundation for SaaSing the Framework per-tenant.


## [0.6.2] — 2026-06-02 17:10:00 Eastern · *LEDGER-0032 — family `claude` SSH fleet docs (sanitized)*

### Added
- `docs/family-fleet-ssh-claude.md` — public fleet SSH map with `192.168.x.y` placeholders only.
- `ledger/LEDGER-0032-claude-ssh-user/` — shipped playbooks, runbooks, `operator-hosts.env.example`,
  `ssh-config-snippet.example`; real hostnames/users stay in gitignored `operator-hosts.env`.

> **What to look for:** Copy `operator-hosts.env.example` → `operator-hosts.env`, fill VPS/DGX
> targets locally, merge `ssh-config-snippet.example` into `~/.ssh/config`; verify
> `ssh ax1800-claude id` and `ssh mt6000-claude` from the operator Mac. Repo must not
> contain your VPS hostname or operator Unix names.

## [0.6.1] — 2026-06-02 15:25:09 Eastern · *LEDGER-0031 closeout — search restored + mTLS-gated; WG root cause fixed*

### Fixed / Shipped
- **search.jailynmarvin.com restored** after a ~13.5h outage and **mTLS-gated**
  (family device cert → 307; cert-less → 400 hidden). Root cause: the VPS
  WireGuard had no fixed `ListenPort` and grabbed a random port on a restart that
  the firewall blocked. Fixed + persisted across all three boxes:
  VPS (pin port + ufw), router (firewall.user reply-path forward + endpoint
  self-heal cron), DGX (systemd symmetric LAN route). Family CA stood up + a device
  cert issued. DGX redeployed to the latest app.
- **Plan diverged prudently:** the VPS edge is shared production nginx (4 other
  businesses) + the installed Caddy lacked the acme-dns module, so mTLS was added
  **in-place in nginx scoped to the jailynmarvin cassettes** rather than the full
  Caddy cutover (which remains future Phase-1 work). LEDGER-0031 ticket updated with
  the real fix set + persistence verification; status → shipped.

## [0.6.0] — 2026-06-02 10:48:05 Eastern · *Triple-threat edge architecture + LEDGER-0031 (Caddy-at-the-helm Phase 1)*

### Added
- `docs/edge-architecture-triple-threat.md` — target edge topology: **Caddy at the
  helm** (mTLS + wildcard DNS-01 + cassette routing, VPS + DGX), **nginx+WAF** as a
  Phase-3 public moat, **Traefik** as a Phase-2 dynamic-container dispatcher. Layered
  defense-in-depth; phased so each earns its keep.
- `ledger/LEDGER-0031-cassette-edge-mtls-wireguard/` — Phase 1 made real:
  `family-ca.sh` (EC P-256 private CA + per-device mTLS certs + revoke/CRL), the
  cassette-edge `Caddyfile` (wildcard DNS-01 via acme-dns + `client_auth` mTLS +
  Host-routing + default-deny), `acmedns.json.example`, and 4 runbooks (CA bootstrap,
  device-cert issue/install, reversible parallel-port Caddy cutover, GoDaddy DNS
  changes). Ledger index reconciled (0028–0031 rows added; Next number → 0032).
- Access model: ops/secrets → WireGuard-only (no public DNS); family apps → public
  but mTLS-gated; one `*.jailynmarvin.com` wildcard covers all.

## [0.5.0] — 2026-06-02 09:43:14 Eastern · *Cassette subdomain & edge architecture (Option A: edge anchor + CNAME per cassette)*

### Added
- `docs/cassette-subdomain-edge-architecture.md` — adopted infra design for
  per-cassette subdomains of the family TLD (`jailynmarvin.com`): a single `edge`
  A record holds the IP; every cassette is a **CNAME → edge** (auditable allowlist,
  no wildcard, per-host TLS, one-edit DGX failover). Includes the security tradeoff
  vs. wildcards, the mandatory **edge default-deny** vhost, the 3-step new-cassette
  ritual, and the reconciliation with the `one-tower-one-url` rule (Tower-embed is
  the default; subdomains are the operator-directed exception). Current live
  cassettes: nephew, search, bank, clinic, git → the VPS edge `72.167.151.251`.

## [0.4.0] — 2026-05-22 21:23:03 Eastern · *LEDGER-0025 — fine-grained PAT lands; sync-and-drift.sh now authenticates*

**Headline:** Option C selected. `sync-and-drift.sh` now reads `/etc/yousirjuan-sync/credentials` at start-of-run and rewrites the GitHub URL base from SSH to HTTPS-with-token. A new idempotent installer (`ledger/LEDGER-0025-.../playbooks/install-credential.sh`) handles the credential file with `0600 root:root` and runs a one-call API smoke test against `/orgs/marvelousempire`. Four runbooks (02–05) cover token generation, credential deploy, script behavior, and end-to-end verification.

### Added

- [`ledger/LEDGER-0025-.../playbooks/install-credential.sh`](../ledger/LEDGER-0025-vps-marvelousempire-deploy-key/playbooks/install-credential.sh) — interactive / `--token` / `--from-stdin` modes; atomic file write; loose token-shape sanity; HTTP-code-aware smoke test (die clearly on 401/403/404).
- [`runbooks/02-generate-pat.md`](../ledger/LEDGER-0025-vps-marvelousempire-deploy-key/runbooks/02-generate-pat.md) — operator-only step (GitHub web UI). Scopes: `contents:read` + `metadata:read`. Cap: 366 days.
- [`runbooks/03-deploy-credential-to-vps.md`](../ledger/LEDGER-0025-vps-marvelousempire-deploy-key/runbooks/03-deploy-credential-to-vps.md) — interactive paste so the token never lands in shell history.
- [`runbooks/04-teach-sync-and-drift.md`](../ledger/LEDGER-0025-vps-marvelousempire-deploy-key/runbooks/04-teach-sync-and-drift.md) — documents the URL-rewrite mechanism and why token-in-URL beats credential-helper here.
- [`runbooks/05-verify-end-to-end.md`](../ledger/LEDGER-0025-vps-marvelousempire-deploy-key/runbooks/05-verify-end-to-end.md) — symptom→fix matrix + the canonical bright-line check (`failures < 5`).

### Changed

- [`ledger/LEDGER-0024-.../playbooks/sync-and-drift.sh`](../ledger/LEDGER-0024-dual-push-drift-prevention/playbooks/sync-and-drift.sh) — reads `$CREDENTIALS_FILE` (default `/etc/yousirjuan-sync/credentials`); when `$GITHUB_TOKEN` is set, rewrites `GITHUB_URL_BASE` to `https://x-access-token:${GITHUB_TOKEN}@github.com/marvelousempire`. Falls back to SSH otherwise (preserves graceful-failure behavior if credentials are absent).
- [`ledger/LEDGER-0025-.../README.md`](../ledger/LEDGER-0025-vps-marvelousempire-deploy-key/README.md) — status `planning → in-progress`; `## Decision (2026-05-22)` block records why Option C beat A/B/D today and where D fits in the roadmap.
- [`ledger/README.md`](../ledger/README.md) — LEDGER-0025 row updated to reflect Option C + the replay one-liner.

### Why Option C and not B / D

- **B (machine user):** GitHub now discourages machine users in favor of GitHub Apps.
- **D (GitHub App):** the right destination for multi-org future, but ~30 lines of token-minting helper + 1-hour refresh logic is more complexity than this single-org context needs today. Filed as the next ledger entry when multi-org is real.
- **C (PAT):** unblocks today, ~10 min from PR-merge to working drift detection. Annual rotation is a calendar event, not an emergency.

### What ships next

When the operator pastes the PAT into the installer on vps-godaddy and triggers a sync, `/var/lib/yousirjuan/dual-push-drift-report.json` should show `failures` drop from 88 → near 0. Status flips to `shipped` then.

## [0.3.0] — 2026-05-22 21:07:54 Eastern · *LEDGER-0025 — VPS deploy-key for marvelousempire (planning ticket)*

**Headline:** LEDGER-0024 v0.2.2 made the drift report parseable, and the first valid report on vps-godaddy showed `failures: 88 / 88` — the systemd timer's root user has no SSH identity that authenticates to `git@github.com:marvelousempire/*`. The drift detector can't read either remote, so no comparison happens. New ledger entry captures the gap, lays out four auth strategies (per-repo deploy keys / machine user / PAT / GitHub App), and parks at `planning` until the operator picks one.

### Added

- [`ledger/LEDGER-0025-vps-marvelousempire-deploy-key/README.md`](../ledger/LEDGER-0025-vps-marvelousempire-deploy-key/README.md) — ticket with the four-option decision matrix, recommended default (machine user if single-org, GitHub App if multi-org coming), and the verification one-liner that closes the loop (`python3 -m json.tool` showing `failures: 0`).
- [`ledger/LEDGER-0025-.../runbooks/01-pick-auth-strategy.md`](../ledger/LEDGER-0025-vps-marvelousempire-deploy-key/runbooks/01-pick-auth-strategy.md) — first runbook, the decision step.

### Changed

- [`ledger/README.md`](../ledger/README.md) — next number bumped `0025 → 0026`; new index row for LEDGER-0025 with status `planning`.

### Why this is here

Per the `version-bump-and-changelog` rule v2: every ledger entry is a logged operator-visible event. Bump + CHANGELOG + tag + Release.

### What ships next

When the operator picks A/B/C/D in `runbooks/01-pick-auth-strategy.md`, the implementation lands as a follow-up minor bump with the playbook + verification.

## [0.2.2] — 2026-05-22 20:59:14 Eastern · *fix LEDGER-0024 drift report JSON (second bug)*

**Headline:** v0.2.1 fixed the embedded-newline bug in the count fields but the JSON was still malformed because every clone-failure logged an `echo "  ✗ clone failed: <repo>"` on stdout, which the parallel `xargs ... >>"$results_tmp"` captured into the entries array between the JSON objects.

The first deploy on vps-godaddy surfaced this — 88 clone failures (likely a separate SSH-key issue), each emitting a non-JSON line that broke the parser at `line 7 column 7 (char 118)`.

### Fixed

- `ledger/LEDGER-0024-dual-push-drift-prevention/playbooks/sync-and-drift.sh` — clone-failure echo now redirects to stderr (`>&2`). The parent script's `exec >>"$LOG" 2>&1` still catches it into the log file, but the xargs subshell's stdout redirect (`>>"$results_tmp"`) no longer sees it. Only the canonical `printf '  {...}\n'` reaches the results file.

### Side benefit

- The `total` count is now accurate. Before this fix, each clone-failed repo wrote 2 lines (echo + JSON) and `wc -l` counted both, doubling the total.

### Verification

```bash
ssh vps-godaddy 'cd ~/Developer/yousirjuan && \
  git pull --ff-only && \
  sudo bash ledger/LEDGER-0024-dual-push-drift-prevention/playbooks/install.sh install && \
  sudo /opt/yousirjuan-sync/sync-and-drift.sh && \
  echo --- && \
  sudo cat /var/lib/yousirjuan/dual-push-drift-report.json | python3 -m json.tool | head -40'
```

### Known follow-up (not this PR)

88 clone failures on vps-godaddy point to an SSH-key / deploy-key gap on the marvelousempire org. That's a separate ledger item — this PR only makes the report parseable so the operator can SEE what's failing.

## [0.2.1] — 2026-05-22 20:39:17 Eastern · *fix LEDGER-0024 drift report JSON*

**Headline:** the dual-push drift report was emitting malformed JSON whenever the drift or failure count was zero (the common case). `python3 -m json.tool` failed with `Expecting ',' delimiter: line 5 column 1 (char 78)` and the operator-facing report was unparseable.

### Fixed

- `ledger/LEDGER-0024-dual-push-drift-prevention/playbooks/sync-and-drift.sh` — replaced `|| echo 0` with `|| true` on the two `grep -c ... || ...` guards. `grep -c` always writes the count to stdout (including `0` for zero matches) and exits non-zero only when zero matches; the old guard appended a *second* `0\n` after the first, producing a literal newline inside the JSON number. `|| true` silences the non-zero exit without contaminating stdout.

### Verification

```bash
# locally:
touch /tmp/empty.txt
NEW="$(grep -cE 'never' /tmp/empty.txt || true)"
echo "[${NEW}]"   # → [0]   (one character, not "0\n0")

# on vps-godaddy after pull + re-install:
sudo /opt/yousirjuan-sync/sync-and-drift.sh && \
  sudo cat /var/lib/yousirjuan/dual-push-drift-report.json | python3 -m json.tool
```

The second command now parses cleanly.

### Deploy path

```bash
ssh vps-godaddy 'cd ~/Developer/yousirjuan && \
  git pull --ff-only && \
  sudo bash ledger/LEDGER-0024-dual-push-drift-prevention/playbooks/install.sh install && \
  sudo /opt/yousirjuan-sync/sync-and-drift.sh && \
  echo --- && \
  sudo cat /var/lib/yousirjuan/dual-push-drift-report.json | python3 -m json.tool | head -40'
```

`install.sh install` is idempotent — it copies the fixed script into `/opt/yousirjuan-sync/` and the systemd timer picks it up on the next 5-min tick (or run it manually as shown).

## [0.2.0] — 2026-05-20 01:36:41 Eastern · *self-codifying ledger + workflow-debugger agent*

**Headline:** yousirjuan grew a permanent **knowledge layer** today — a `/ledger/` system where every non-trivial task lands as ticket + runbook + executable playbook, so the same task doesn't need an AI the second time. First two entries shipped: the iMac MCP development stack (the embryo that proved the pattern), and a `workflow-debugger` specialist agent for YAML/Bash/JS/Python/Excel pipeline bugs.

### Added

- **`/ledger/` system** — top-level home for replayable task knowledge ([`ledger/README.md`](../ledger/README.md), [`ledger/_template/`](../ledger/_template/)). Index + format-choice guide + helper-function snippet + triggers table. Soft rule: [`.claude/rules/ledger-discipline.md`](../.claude/rules/ledger-discipline.md).
- **LEDGER-0001** — iMac MCP development stack (VS Code + Cline + Ollama-as-LaunchAgent, all reproducible via `make install` from [`ledger/LEDGER-0001-imac-mcp-setup/playbooks/Makefile`](../ledger/LEDGER-0001-imac-mcp-setup/playbooks/Makefile)). 5 runbooks, 1 Makefile, 1 shell playbook (`install.sh` for environments without `make`), 1 launchd plist. Resolves [`PAIN-0006`](../pain-journal/PAIN-0006-ollama-app-incompatible.md), [`PAIN-0007`](../pain-journal/PAIN-0007-code-cli-not-on-path.md), [`PAIN-0008`](../pain-journal/PAIN-0008-copilot-paywall.md), [`PAIN-0009`](../pain-journal/PAIN-0009-mcp-config-fragmented.md), [`PAIN-0010`](../pain-journal/PAIN-0010-intel-cpu-no-gpu.md).
- **LEDGER-0002** — `workflow-debugger` Claude Code agent at [`.claude/agents/workflow-debugger.md`](../.claude/agents/workflow-debugger.md). Specialist for YAML/Bash/JavaScript/Python/Excel pipeline failures. Encodes symptom-first diagnostic loop, willingness to discard wrong hypotheses fast, gotcha catalog per language, and verification ritual. Project-scoped by default; user-scope install via [`ledger/LEDGER-0002-workflow-debugger-agent/playbooks/install-user-scope.sh`](../ledger/LEDGER-0002-workflow-debugger-agent/playbooks/install-user-scope.sh).
- **Auto-sync hook** — `PostToolUse` hook in [`.claude/settings.json`](../.claude/settings.json) automatically re-syncs the workflow-debugger agent from project scope to user scope whenever the project-scope file is edited. Controllable via the `/hooks` slash-command UI in Claude Code.
- **CLI snippet formatting rule** — [`.claude/rules/cli-snippet-formatting.md`](../.claude/rules/cli-snippet-formatting.md). Every agent in this repo formats shell snippets as one copy-pasteable block with `\` continuations and `&&` chaining; never split across multiple fenced code blocks.

### Changed

- **HANDOFF.md** §7 — appended Day 4 (2026-05-19) entry covering the MCP stack work, with pointers into the new ledger. Frontmatter `Latest update:` line refreshed.
- **CI contract enforcement workflow** loosened — explicit allowlist for product-doc files where Associate Agent / interface UX references are intentional (CLAUDE.md, README.md, docs/marketing/**, etc.). The workflow had been failing on every main push since it was added; now passes.

### Fixed

- **`release-intel-mac.yml`** workflow YAML parse error. Lines 93–107 were at column 1 inside a `run: |` literal block whose first content line was at 10-space indent. YAML was terminating the block at the first under-indented line and trying to parse `One-liner:` as a sibling key. Rewrote the "Publish to marvelousempire/yousirjuan-ai releases" step to use `cat <<EOF | sed 's/^          //' > /tmp/release-notes.md` so heredoc content satisfies YAML indentation but renders left-aligned. Workflow now correctly fires only on `v*.*.*` tag pushes + `workflow_dispatch`. (Em-dash hypothesis in PR #9 was a red herring — see [`Issue-Log.md`](Issue-Log.md).)

### Infrastructure / repo plumbing

- Migrated `docs/sessions/2026-05-19-mcp-setup/` → `ledger/LEDGER-0001-imac-mcp-setup/` and reshaped to the ledger schema (`artifacts/Makefile` → `playbooks/Makefile`, new ticket README with YAML frontmatter, etc.). All cross-file links updated.
- Added `.claude/agents/` directory (new project-scoped agent home).
- Added `ledger/_template/` skeleton for new ledger entries.

### Ships behind

- `bishop` / `bishop-factory` repo consolidation (the two are byte-identical duplicates; archive `bishop-factory`, keep `bishop` as canonical). Documented in plan file at [`~/.claude/plans/what-is-the-best-curious-willow.md`](~/.claude/plans/what-is-the-best-curious-willow.md) §"Part 2"; not shipped today.
- CI hardening for the ledger pattern — a check that fails PRs touching `runbooks/**` or `playbooks/**` outside a `LEDGER-NNNN/` folder. Wait until ~5 real ledger entries exist before adding.

### PRs

[#4](https://github.com/marvelousempire/yousirjuan/pull/4), [#5](https://github.com/marvelousempire/yousirjuan/pull/5), [#7](https://github.com/marvelousempire/yousirjuan/pull/7), [#8](https://github.com/marvelousempire/yousirjuan/pull/8), [#9](https://github.com/marvelousempire/yousirjuan/pull/9) (em-dash red herring — see Issue-Log), [#10](https://github.com/marvelousempire/yousirjuan/pull/10) (real workflow fix), [#11](https://github.com/marvelousempire/yousirjuan/pull/11), [#12](https://github.com/marvelousempire/yousirjuan/pull/12), and the chore PR that ships this changelog.

### Version bumps

Platform monorepo (Node packages, all in lockstep): root [`package.json`](../package.json), [`apps/admin/package.json`](../apps/admin/package.json), [`apps/yousirjuan-web/package.json`](../apps/yousirjuan-web/package.json), [`services/homekit-bridge/package.json`](../services/homekit-bridge/package.json) — all 0.1.0 → 0.2.0.

**`apps/yousirjuan-ios` is NOT bumped** and intentionally runs on a separate cycle. The iOS app is at `CFBundleShortVersionString = 1.0` / `CFBundleVersion = 1` (see [`Info.plist`](../apps/yousirjuan-ios/Sources/Info.plist)); iOS marketing versions follow App Store review cycles, not the platform's `0.x` semver. Earlier I claimed there was "no discoverable version surface" — that was wrong; the surface exists, it's just on a different cycle.

---

## [0.1.0] — baseline (pre-2026-05-20)

Initial yousirjuan platform: README, HANDOFF.md, REPOS-CONTRACT.md, CI-CONTRACT-GUIDE.md, CLAUDE.md (Claude Code agent routing guide), `installers/intel-mac/install.sh`, `docker-compose.yml` with the stack (Ollama, Open WebUI, Qdrant, Postgres, Redis, Kokoro, nginx), `apps/yousirjuan-web/` + `apps/admin/` + `apps/yousirjuan-ios/`, `vendor/ai-skills-library/` submodule wiring, `pain-journal/` (entries PAIN-0001 through PAIN-0005), VPS deployment scripts, GitHub Actions workflows, contract-enforcement CI.

Reconstructed retroactively from git history — no per-PR changelog was maintained pre-0.2.0. Anything earlier than today's `0.2.0 entry` lives in git log and HANDOFF.md §7's session timeline (Days 1–3, 2026-04-24 through 2026-04-26).
