# Runbook — DGX ↔ NAS direct 10 GbE storage link

**Goal:** move NAS I/O from the slow LAN path (~40 MB/s, DGX USB-2.0 ethernet dongle) to a **direct 10 GbE cable** DGX ↔ UGREEN DXP6800 Pro → **~1 GB/s**.
**Verified live:** 2026-07-01 — write ~900 MB/s (HDD pool) / ~1.0 GB/s (SSD pool).
**IaC equivalent:** [`ansible/roles/nas_10gbe_mount`](../../ansible/roles/nas_10gbe_mount) + [`ansible/playbooks/dgx-linux.yml`](../../ansible/playbooks/dgx-linux.yml).

---

## Topology

```
DGX Spark  enP7s7 (10 GbE RJ-45, 10.77.0.2/30)  ──cable──  NAS LAN2 (10 GbE, 10.77.0.1/30)
DGX Spark  USB dongle (1 GbE, 192.168.10.205)  ──►  Flint 2 router  ── internet + LAN
NAS        LAN1 (2.5 GbE, 192.168.10.119)       ──►  Flint 2 router  ── LAN services
```

The DGX has **one** built-in 10 GbE RJ-45 (its 2× QSFP ConnectX-7 ports are for Spark-to-Spark clustering, not the NAS). So the NAS gets a **direct point-to-point** cable on a tiny `/30` subnet; internet/LAN keeps flowing over the USB dongle + LAN1.

---

## Steps (what we did — reproducible)

### 1. Physical (Boss Move)
- Cable the **DGX 10 GbE RJ-45 (`enP7s7`)** directly to a **10 GbE port on the NAS** (the DXP6800 Pro's LAN2). No switch needed — point-to-point.

### 2. NAS side — static IP on the 10 GbE port (UGOS)
`Control Panel → Network → Network connection → LAN2 (the 10 GbE port) → Edit → IPv4 → Set manually`:
- IPv4 `10.77.0.1` · Subnet `255.255.255.252` · **Gateway `10.77.0.2`** (the /30 requires a gateway; the DGX end is the only valid value — harmless, it's directly connected) · DNS blank.
- `Service order`: keep **LAN1 first** so the NAS's default route (internet) stays on LAN1, not this dead-end link.

> Why gateway `10.77.0.2`: UGOS rejects an empty gateway on a manual IP. On a `/30` the only in-subnet host is the peer, and directly-connected traffic never routes through it, so it's cosmetic.

### 3. NAS side — allow the 10 GbE subnet in NFS (UGOS)
`Control Panel → Shared Folder → <folder> → NFS Permissions → Add rule`, for each fast folder (`media`, `docker`, …):
- Client `10.77.0.0/24` · Privilege **Read/Write** · Squash = match the existing `192.168.10.0/24` rule.
- **Keep** the existing `192.168.10.0/24` rule too.

> Symptom if skipped: `mount.nfs: access denied by server` — the export ACL didn't include the DGX's `10.77.0.2`.

### 4. DGX side — IP + mounts (automated by Ansible; manual form below)
```bash
# 10 GbE interface IP (persist via netplan/NetworkManager or the ansible role)
sudo ip addr add 10.77.0.2/30 dev enP7s7   # runtime; make persistent in netplan
ping -c2 10.77.0.1                          # expect <1ms

# point the NAS mounts at the 10 GbE peer + persist in fstab
sudo sed -i 's#192.168.10.119:/volume2/media#10.77.0.1:/volume2/media#;   s#192.168.10.119:/volume1/docker#10.77.0.1:/volume1/docker#' /etc/fstab
# fstab line shape:  10.77.0.1:/volume2/media  /mnt/nas-media  nfs  vers=3,nolock,rw,nofail,_netdev  0 0

sudo umount /mnt/nas-media && sudo mount /mnt/nas-media
sudo umount /mnt/nas-docker || sudo umount -l /mnt/nas-docker   # lazy if busy
sudo mount /mnt/nas-docker
```

### 5. Verify + benchmark
```bash
mount | grep 10.77.0.1                       # both mounts on the 10 GbE peer
ethtool enP7s7 | grep -i speed               # Speed: 10000Mb/s
# write (honest — flushes to disk):
sudo dd if=/dev/zero of=/mnt/nas-docker/.b bs=1M count=2000 conv=fdatasync   # ~1.0 GB/s
sudo rm -f /mnt/nas-docker/.b
```

---

## Gotchas (learned the hard way)

| Symptom | Cause | Fix |
|---|---|---|
| 10 GbE link "up" but peer silent | NAS LAN2 on DHCP → self-assigned `169.254.x` (no DHCP on the direct link) | set LAN2 static `10.77.0.1/30` |
| `access denied by server` on mount | NFS export ACL only had `192.168.10.0/24` | add `10.77.0.0/24` RW to each folder |
| `umount: device is busy` (nas-docker) | a container/service holds handles | `umount -l` (lazy) then remount; clean on reboot via fstab |
| NAS lost internet after adding LAN2 gateway | LAN2 gateway hijacked the default route | `Service order` → LAN1 first |
| Read benchmark shows 20+ GB/s | client page-cache hit, not the wire | trust the **write** number, or `echo 3 > /proc/sys/vm/drop_caches` |

## Rollback
`sudo cp /etc/fstab.bak-* /etc/fstab` then remount, or edit the two lines back to `192.168.10.119`. The LAN path (LAN1 / the USB dongle) is untouched.

## Optional next
- **MTU 9000 (jumbo frames)** on both `enP7s7` and NAS LAN2 for a bit more throughput (both ends must match).
- Move the DGX's 1 GbE dongle off its **USB 2.0** port onto a **20 Gb/s USB-C** port for faster LAN/internet.
- Dedicated `ai-models` share on the NAS **SSD pool (Pool 1)** for the family model cache.
