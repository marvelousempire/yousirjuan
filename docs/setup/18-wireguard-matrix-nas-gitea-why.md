# Chapter 18 — WireGuard, Matrix, NAS Docker & Gitea (Why We Chose This)

**Public-safe:** architecture, reasons, and operator vocabulary. No keys, peer configs, or passwords.

---

## Chapter intents

| Intent | Why |
|---|---|
| **Encrypted mesh** | Reach DGX, NAS, and VPS privately — no open LAN on AI ports |
| **Protectli path** | Dedicated OPNsense firewall replaces consumer router as security brain |
| **NAS = durable tier** | Git objects, backups, Historia vault, Docker heavy storage — not GPU workloads |
| **Gitea over GitLab** | Lighter forge on our metal; GitHub stays collaboration mirror |
| **Matrix = family chat** | Self-hosted E2EE — no Slack/Discord data exfil |
| **Doors on top** | WireGuard gets you to the mesh; doors give you human names |

---

## WireGuard mesh (how private access works)

### Section intents

| Intent | Why WireGuard |
|---|---|
| **Replace Tailscale billing** | Self-hosted overlay on our keys — sovereign |
| **Close LAN ports** | Plan 0180: services bind loopback + WG only — Wi-Fi clients can't hit `:8088` |
| **Remote family** | Phones/laptops tunnel to home — reach DGX/NAS as if local |
| **VPS ↔ home** | Public edge reaches compute over mesh — not port-forward spaghetti |

```text
[Mac / iPhone / iPad] ──WG tunnel──► [Home gateway peer]
                                           │
                    ┌──────────────────────┼──────────────────────┐
                    │                      │                      │
              DGX Spark              NAS DXP6800            VPS edge
              wg0 10.1.0.5           (storage)              wg0 10.1.0.2
              LLM RAG voice          git objects            Clinic HTTPS
              Gitea Matrix           Historia vault         family apex
```

| Host | WireGuard role | Intent |
|---|---|---|
| **Home gateway** (MT6000 today → **Protectli OPNsense** target) | UDP endpoint, peer hub, DNS forward | Stable off-LAN entry |
| **DGX Spark** | Primary compute peer `.5` | All AI containers bind here |
| **VPS** | Edge peer `.2` | Public HTTPS → proxy over WG to DGX |
| **Each Mac / phone** | Client peer | Operator + family remote access |

**Access rule:** A device must be a **mesh peer** to reach internal services. Curl to LAN IP on closed ports **should refuse** — that is correct behavior.

### Reaching DGX and NAS behind the mesh

| Goal | Intent | Path |
|---|---|---|
| **Gitea web** | Git forge UI | WG → `10.1.0.5:3300` or door `http://gitea.localhost/` |
| **tower-api** | JSON API only — not a browser UI | WG → DGX `:8088` |
| **NAS admin** | UGOS web UI | LAN/WG → NAS HTTPS or door `http://nas-ugos.localhost/` |
| **Matrix Element** | Family chat | WG → `:8009` or `http://matrix-element.localhost/` |
| **Qdrant / embed** | Internal — agents use tower-api retrieve | Docker network on DGX — not browser |

### Protectli VP6670 (arriving / cutover)

### Intents

| Intent | Why Protectli |
|---|---|
| **OPNsense** | Real firewall — VLANs, IDS, DNS, DHCP, WG server in one box |
| **MT6000 demotion** | Consumer router → AP mode after migration — Wi-Fi stays, routing moves |
| **Brume 3** | Dumb switch today → travel WG **client** after cutover |
| **VLAN enforcement** | Trusted `.10` / IoT `.11` / Guest `.20` — deny cross-zone first |

Ten-step migration checklist: [13-physical-topology-protectli.md](./13-physical-topology-protectli.md) · Full microscopic steps: [`home-network-full-architecture-report.md`](../home-network-full-architecture-report.md) §7.7

**Boss Move:** Export MT6000 `.CFG` backup **before** any cutover step.

---

## Family Office Sandwich (network + doors)

### Intents

| Layer | Intent |
|---|---|
| **One public edge** | Single VPS HTTPS gate — auth + TLS |
| **WG mesh** | Encrypted overlay — everything internal |
| **Closed LAN binds** | Not security through obscurity — auth + membership |
| **Doors** | Human names on operator Mac gateway |

Security locks = **WireGuard membership + family auth + edge TLS** — not hiding port numbers.

---

## Matrix + Element (Family Chat)

### Intents

| Intent | Why Matrix |
|---|---|
| **E2EE family chat** | End-to-end encrypted rooms — our keys, our server |
| **Federation OFF** | No public Matrix federation — homeserver stays private |
| **WG-only remote** | No public Element URL — VPN overlay for off-LAN |
| **AI bot optional** | `@ai-bot` bridges to Hermes/RAG when enabled |

| Component | Role | Intent |
|---|---|---|
| **Synapse** | Homeserver `:8008` | Account + room authority |
| **Element Web** | Client `:8009` | Browser UI for family |
| **matrix-ai-bot** | Optional bridge | Room messages → Nephew inference |

**Cassette id:** `matrix-element` (embed-app cassette)

| Operator door | What you get |
|---|---|
| `http://matrix-element.localhost/` | Full Element Web page |
| `http://element.localhost/` | Alias door |

Manifest: `data/control-tower-apps.manifest.json` → row `matrix-element`  
Stack: `deploy/matrix/docker-compose.yml` on DGX (`~/stacks/matrix`)  
Boot: `cd ~/stacks/matrix && docker compose up -d`

**Privacy:** No `remote_embed_url` — intentional. Public Pockit tile shows VPN overlay when off mesh.

Plan 0197: Matrix may migrate to **NAS Docker** for heavy storage tier — DGX keeps GPU workloads.

---

## Docker on NAS (storage tier migration)

### Intents

| Intent | Why NAS Docker |
|---|---|
| **Free DGX GPU RAM** | WordPress, Gitea, Matrix don't need GPU — move to NAS |
| **Durable data local to RAID** | Git objects + media already on NAS — compute follows data |
| **10GbE path** | DGX ↔ NAS direct link — low latency for moved services |
| **Keep GPU on DGX** | Ollama, Qdrant hot index, embeddings, voice, ComfyUI stay |

| Workload | Target host | Intent |
|---|---|---|
| Ollama / Qdrant / tower-api / voice | **DGX** | GPU + low-latency RAG |
| Gitea git objects | **NAS** (already) | RAID durability |
| Gitea app / WordPress / Matrix | **NAS Docker** (Plan 0197) | Heavy storage, no GPU |
| Historia vault | **NAS** | Sovereign wiki mount |
| Qdrant snapshots / backups | **NAS** | Cold backup; hot index stays DGX until Plan 0105 |

Bootstrap: nephew `scripts/bootstrap-nas-docker.sh`, `scripts/setup-nas-fleet.sh`  
Verify: `scripts/preflight-nas-docker.sh`

---

## Gitea vs GitLab vs GitHub (why this layout)

### Chapter intents

| Intent | Decision |
|---|---|
| **Push without friction** | Day-to-day `git push` to forge — no PR gate on forge `main` |
| **GitHub for collaboration** | Protected `main`, PR review, public/open-source mirror |
| **No GitHub Actions billing** | CI on self-hosted GitLab runner *when needed* — default ship path is local verify + laptop deploy |
| **Lightweight forge** | **Gitea** on our DGX/NAS — not full GitLab CE overhead for daily pushes |
| **Token-free SSH** | All remotes `git@github.com:...` — macOS keychain, no PAT expiry |

### Three remotes, three jobs

| Remote | Intent | Workflow |
|---|---|---|
| **Gitea (forge)** | Fast inner loop — direct push to `main` | `git push gitea main` · SSH to DGX `:2424` |
| **GitHub (origin)** | Collaboration + offsite mirror | PR to protected `main` · squash merge |
| **GitLab (VPS)** | Optional CI runner host | Pipeline when GitLab online — not default deploy gate |

### Why Gitea instead of GitLab as daily forge

| Reason | Detail |
|---|---|
| **Resource footprint** | Gitea is lighter — important on constrained always-on box |
| **We already run it** | Forge live with NAS-backed repos + GitHub mirror push |
| **SSH on :2424** | Same key as GitHub — `gitea-dgx` host alias |
| **Self-heals on boot** | systemd + git-tracked compose |
| **GitLab investigation** | Documented migration path exists — trigger when GitLab VPS returns from load pause |

### Why not GitHub-only

| Reason | Detail |
|---|---|
| **Sovereign** | Git objects on family RAID — not only Microsoft's cloud |
| **No PAT churn** | SSH to forge eliminates token expiry pain |
| **Direct push lane** | Agents/operators push fast without waiting for PR bot |

### Why GitHub still exists

| Reason | Detail |
|---|---|
| **Branch protection** | Prevents stale force-push clobber (documented incident) |
| **Collaboration UI** | `gh pr create`, reviews, releases |
| **Offsite mirror** | Gitea push-mirrors to GitHub automatically |

### Gitea layout

| Piece | Location | Intent |
|---|---|---|
| Web UI | DGX `:3300` | Browser + OIDC SSO |
| Git SSH | DGX `:2424` | Daily push/pull |
| Git objects | NAS RAID mount | Survive DGX rebuild |
| SQLite DB | DGX local | **Never on NFS** — Gitea requirement |
| Mirror to GitHub | Gitea push mirror | Offsite backup of record |

Doors: `http://gitea.localhost/` · Public gated: `https://git.jailynmarvin.com/`

---

## Single sign-on (family surfaces)

### Intents

| Intent | Why OIDC from tower-api |
|---|---|
| **One login** | Family apex cookie → subdomains |
| **GitLab/Gitea/Portainer** | OIDC clients when configured — operator bypass with `is_operator` |
| **Per-cassette ACL** | Family members see only entitled tiles |

tower-api OIDC: RS256 id tokens (GitLab compatibility). Details in nephew agent briefing (private version has domains).

---

## Onboarding checklist (new Mac on mesh)

1. **Join WireGuard** — required before any internal URL works off-LAN  
2. **SSH config** — GitHub + `gitea-dgx` host blocks, keychain  
3. **Clone nephew** — standard developer path  
4. **`make hooks`** — secret hygiene guards  
5. **`make doors`** — canonical `.localhost` URLs  
6. **Verify** — forge health + one cassette door + retrieve smoke  

---

## Related

- [02-network-security.md](./02-network-security.md) — bind model summary
- [07-git-and-deploy.md](./07-git-and-deploy.md) — ship cycle + dual-push guards
- [13-physical-topology-protectli.md](./13-physical-topology-protectli.md) — cabling + Protectli
- [15-doors-cassettes-pockit-navigation.md](./15-doors-cassettes-pockit-navigation.md) — door names
- Nephew: `docs/infrastructure/family-office-network.md`, `docs/pockit/Family-Chat-Private-Cassette.md`, `plans/0197-nas-docker-heavy-storage-migration.md`
