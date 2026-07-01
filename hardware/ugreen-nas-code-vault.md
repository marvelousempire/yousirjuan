# UGREEN NAS — Code Vault + Builds + Model Storage

**Live hardware:** **UGREEN NASync DXP6800 Pro** (`nasa.local` / `192.168.10.119`) — UGOS Pro.  
**Canonical specs:** [`docs/setup/32-hardware-full-spec-sheet.md`](../docs/setup/32-hardware-full-spec-sheet.md) · [`hardware/ugreen-dxp6800-pro-spec.md`](./ugreen-dxp6800-pro-spec.md)

This file retains the **original vault layout plan** (written when a 4-bay DXP4800 was under consideration). The installed chassis is the **6-bay DXP6800 Pro** — treat pool/bay numbers in ch. 32 as authoritative for what is in the rack today.

---

## Role in the family hardware mesh

Splits the DGX Spark's current dual role into two:

| Hardware | Before NAS | After NAS |
|---|---|---|
| **DGX Spark** | Agents + models + (some code) | **Agents only.** AI runtime, hermes container, Ollama, qwen2.5:32b, embedding models, agent inference. No code execution. No build artifacts. No persistent dev state. |
| **UGREEN NAS** | n/a | **Code + builds + model weights + backups.** Git working copies, Docker volumes, build outputs, large model files, snapshots of `~/.nephew`, snapshots of `~/.hermes/state.db`. |
| **MacBook Pro M5** | Orchestration + sometimes code execution | **Orchestration only.** Editing in Cursor / Claude Code, browser to CT, iMessage bridge daemon. Code is read from / written to the NAS over SMB or NFS. |

This is the architectural intent stated by Avery on 2026-05-28:
> I just want the Spark to be for powering, storing and running agents. I'll have another drive for running code from maybe a NAS UGreen 4 Bay with Red Wolf 4X4 TB raid in there.

(Note: "Red Wolf" in the operator's quote → Seagate **IronWolf** is the canonical NAS HDD line; "Red" is WD's NAS line. Both are good options. Defaults below assume Seagate IronWolf Pro.)

---

## Recommended specs

| Component | Recommendation | Why |
|---|---|---|
| **Chassis** | UGREEN DXP4800 Plus (4-bay) | 4 bays, 10GbE built in, sufficient CPU for SMB/NFS, good iOS app integration. The non-Plus saves ~$200 but loses 10GbE — get the Plus. |
| **Disks** | 4 × Seagate IronWolf Pro 4TB (ST4000NT001) | 5-year warranty, 24×7 NAS-rated, MTBF 1.2M hrs. **Alternative:** WD Red Pro 4TB if you prefer WD. |
| **RAID** | **RAID 5** for capacity (~11.5TB usable, single-disk fault tolerance) OR **RAID 10** for performance + survivability (~8TB usable, can lose one disk per mirror). For a code + model vault: **RAID 5 wins** — capacity matters more than raw IOPS for code + model files. |
| **Filesystem** | btrfs (UGREEN default) — for hourly snapshot support. ext4 is simpler if snapshots aren't needed. **Default: btrfs.** |
| **Network** | 10GbE direct to Mac + 10GbE to DGX (if DGX has 10GbE NIC; otherwise 2.5/1GbE) | Fast code access from any host is the whole point. |
| **Power** | UPS on the NAS (CyberPower CP1500AVRLCD or similar) | Prevent RAID corruption on power loss. |
| **Backups** | Off-site: Backblaze B2 sync (encrypted) of critical paths nightly | Single NAS is single point of failure even with RAID. |

---

## What lives on the NAS

```
/volume1/
├── code/                          # Read-write from Mac + DGX (SMB/NFS shares)
│   ├── nephew/                    # Working copy (Mac edits, DGX reads if needed)
│   ├── yousirjuan/
│   ├── ai-skills-library/
│   └── …every operator repo…
│
├── builds/                        # Build outputs — never committed
│   ├── nephew-ct-dist/
│   ├── tauri-targets/
│   └── docker-volumes/
│       └── hermes-state-snapshots/  # Nightly snapshot of ~/.hermes/state.db
│
├── models/                        # Large model weights — shared between Mac (LM Studio?) and DGX (Ollama)
│   ├── qwen2.5-32b.gguf
│   ├── llama-3.3-70b.gguf
│   ├── embedding-models/
│   └── README.md                  # How each model is used
│
├── archives/                      # Long-term retention
│   ├── grok-exports/
│   ├── claude-chat-archives/
│   └── meta-library-snapshots/
│
├── snapshots/                     # btrfs snapshots (auto via UGREEN UI)
│   └── code-snapshots-daily/
│
└── operator-secrets/              # Encrypted vault (age + sops or 1Password CLI)
    └── …
```

---

## Mount strategy

### From the Mac

SMB share, auto-mount on login via `~/Library/LaunchAgents/com.marvelousempire.nas-code-mount.plist`:

```bash
mount_smbfs //avery@nas.local/code   /Volumes/Code
mount_smbfs //avery@nas.local/models /Volumes/Models
```

Then `~/Developer` either symlinks to `/Volumes/Code` or the operator works directly out of `/Volumes/Code` — pick one, document the choice.

### From the DGX Spark

NFS share, mounted at boot via `/etc/fstab`:

```
nas.local:/volume1/models  /mnt/nas-models  nfs  ro,defaults,_netdev  0  0
nas.local:/volume1/builds  /mnt/nas-builds  nfs  rw,defaults,_netdev  0  0
```

Ollama on the DGX reads model files from `/mnt/nas-models/`.

### From the VPS

The VPS does NOT get a NAS mount — it pulls deployed bundles from the NAS via SSH/SCP or via GitLab CI artifacts. The VPS stays minimal and replaceable.

---

## Migration plan (when the NAS arrives)

1. **Day 1 — physical install:** Rack the UGREEN, install 4×IronWolf, configure RAID 5 in btrfs, bring up SMB + NFS shares, run smoke test (10GbE iperf3 from Mac, NFS read test from DGX).
2. **Day 2 — code migration:** `rsync -avh ~/Developer/ /Volumes/Code/` on the Mac. Update `.zshrc` aliases. Open Claude Code on a NAS-hosted repo to confirm latency is acceptable.
3. **Day 3 — model migration:** `rsync -avh ~/.ollama/models /Volumes/Models/ollama/`. On the DGX: stop hermes container, point Ollama at NFS-mounted models, restart, verify qwen2.5:32b loads.
4. **Day 4 — backups:** Configure Backblaze B2 sync for `/volume1/code/` and `/volume1/operator-secrets/`. Test restore.
5. **Day 5 — DGX cleanup:** Once everything works from the NAS, free up DGX local disk. Run `make hermes-restart` to confirm the container still boots cleanly with NAS-mounted models.

After migration the DGX disk should drop to <500GB used (only OS + container layers + state.db + caches). The 3.4TB it had free becomes available for agent workspaces and inference caches.

---

## Performance budget

| Workload | Acceptable latency | Mitigation if slow |
|---|---|---|
| Cursor / Claude Code reads | <50ms | 10GbE, SMB caching on Mac |
| pnpm install | <2× local SSD time | Run `pnpm install` to local `node_modules` (symlink), keep source on NAS |
| Docker volume reads on DGX | <100ms | NFS over 10GbE; pin hot volumes to local SSD if needed |
| Ollama model load | First load slow (network), subsequent fast | Ollama caches loaded weights in RAM; first load over NFS is fine |

If pnpm install over SMB is unacceptable, fall back: keep `node_modules` on local SSD, source on NAS. Standard pattern.

---

## Open questions (decide when ordering)

- [ ] UGREEN DXP4800 vs DXP4800 Plus — **default to Plus** for the 10GbE
- [ ] 4×4TB IronWolf Pro vs WD Red Pro — **default to IronWolf Pro**
- [ ] RAID 5 vs RAID 10 — **default to RAID 5** for code + models
- [ ] btrfs vs ext4 — **default to btrfs** for snapshots
- [ ] Direct 10GbE Mac↔NAS or through a switch — direct is simpler if only Mac + NAS need 10GbE
- [ ] UPS sizing — CyberPower CP1500AVRLCD is enough for NAS + router

---

## Cost estimate (mid-2026)

| Item | Approx |
|---|---|
| UGREEN DXP4800 Plus | $700 |
| 4 × IronWolf Pro 4TB | $700 ($175 each) |
| CyberPower UPS | $200 |
| 10GbE SFP+ cables/DAC | $40 |
| Backblaze B2 (first year) | ~$60 |
| **Total** | **~$1,700** |

---

## Related

- **DGX role doctrine:** [`hardware/dgx-spark-frontier-node.md`](./dgx-spark-frontier-node.md) — DGX's role as agent runtime only (after the NAS arrives)
- **Hardware inventory:** [`docs/hardware-topology.md`](../docs/hardware-topology.md)
- **Family Office Sandwich:** [`marvelousempire/nephew` `data/nephew-soul.md`](https://github.com/marvelousempire/nephew/blob/main/data/nephew-soul.md) — why everything stays on family-controlled hardware
- **Pain Journal:** [`pain-journal/`](../pain-journal/) — any incidents that drive future NAS hardening
