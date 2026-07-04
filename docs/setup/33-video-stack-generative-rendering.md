# Chapter 33 — Video Stack: Sovereign Generative Rendering (ComfyUI · Heavy Windows · Identity)

**Public-safe** · how the family generates video and images on its own hardware: the render server, the engines that are *proven* (with the receipts that proved them), the heavy-window law that keeps one GPU serving many tenants, and the identity path that holds a real face across frames.

**Canonical technical copy (mirrored):** `marvelousempire/standard-video-stack` → `understandings/Super-Rick-Video-Stack-Ledger.md` (the start-here scorecard — every claim below carries a dated receipt there)
**Runtime owner:** `marvelousempire/nephew` → `src/video/` (pipeline, graphs, processors), `deploy/dgx/fleet/comfyui/`, `data/video-config.json`

Complements [Chapter 31 — Inference floor](./31-m5-max-dgx-inference-setup.md) (the GB10 memory-pool reality this chapter's window law answers), [Chapter 15 — Doors & cassettes](./15-cassettes-doors-family-gateway.md), and [Chapter 18 — WireGuard matrix](./18-wireguard-matrix-nas-gitea-why.md).

---

## 1. One render server, behind the mesh

**ComfyUI** runs as a fleet cassette on the DGX (`nephew-fleet-comfyui-1`, port `8188`, bound to loopback + the WireGuard address only). The pipeline that drives it lives on the Mac in tower-api — prompt in at `POST /api/v1/video/render`, engine graph out over the mesh. The config of record (`data/video-config.json` → `comfyui.url`) points the pipeline at the DGX; env can override. **History lesson:** for weeks the pipeline silently defaulted to the Mac's own loopback and could never reach the real server — reachability is config-of-record now, never an unset-env default.

## 2. The engines — proven, loaded, or honestly retired

| Engine | State | Receipt (2026-07-04) |
|--------|-------|----------------------|
| **SD-Turbo** (image) | ✅ render-proven | 512² in **2.0 s warm** — the stack's "first verified render" |
| **Flux.1-schnell fp8** (image) | ✅ loaded | 17 GB checkpoint listed by the loader |
| **Wan 2.2 TI2V-5B** (video) | ✅ render-proven | 96 s smoke + a full mp4 through the operator API |
| **HunyuanVideo t2v** (video) | ✅ render-proven | 348 s, 33 frames — after a graph rework to the official split loaders |
| **HunyuanVideo i2v v2** (identity) | ✅ render-proven | the §5 face-consistency chain, 310 s |
| **LTX-Video 2B** (fast video) | ✅ loaded | single scoped 6.3 GB checkpoint (of a 12-variant repo) |
| **CogVideoX-5B** | ⏸ retired — routed | no ComfyUI-core support; its fast-draft role is covered by LTX; the adapter path (kijai wrapper + a measured receipt) is documented, not deleted |

**Weights discipline** (the 185 GB lesson): list the repo *before* downloading a byte, take exactly the files the graphs name, resumable `wget -c`, then back-populate the NAS vault (`/volume2/media/ai-models/comfyui/`) and register every file in `data/model-storage-registry.json`. Bootstrap: `scripts/bootstrap-comfyui-video-weights.sh` — it downloads single files, never snapshots.

## 3. The heavy-window law

The GB10 has **one 121 GB unified pool** shared by the chat brain, TTS, rerankers, and this render server. A 17-frame smoke run with the other tenants resident once drove the box to **load 629** and starved every service on it — including ComfyUI's own API, so the job couldn't even be interrupted.

**The law: video renders are heavy-window-only.**

```bash
# on the DGX (nephew checkout)
bash deploy/dgx/fleet/heavy-mode.sh on  "why this window exists"   # evicts the big tenants (ledger-logged), boots ComfyUI → ~100 GB free
# … render …
bash deploy/dgx/fleet/heavy-mode.sh off "window closed"            # restores the daily chat lane
```

The wrapper drives the `video-heavy` runtime lane — every eviction and start is written to the DGX service ledger with a WHY, so no agent ever wonders who stopped what. Same render that thrashed the box: **96 seconds** inside a window.

**Known interaction:** the tower-api responsiveness watchdog can kill the Mac daemon *during* a window (its chat model is evicted, health probes wedge). Submit at the start of the window; re-ensure tower-api after. The structural fix — a lane-aware watchdog — is a named gap row in the Ledger.

## 4. Operator surfaces

| Surface | Where |
|---------|-------|
| API | `POST /api/v1/video/render` on tower-api (engine, prompt, optional `reference_image`) |
| Door | `http://video.localhost/` |
| Briefcase | the **Vision** tab (sixth console tab) |
| Pockit | `#/c/video` ("Rick Video") |

## 5. Identity — a real face, held across frames

The face-consistency path (Phase 2, shipped): hand the API a **reference still** and the render auto-upgrades to the HunyuanVideo **i2v v2 ("replace")** graph — the image is encoded by a vision tower and used as both conditioning and the starting latent, so the subject's face holds for the whole clip. Explicit engine choices are never overridden (that guarantee is tested — a config once silently rewrote every render's engine, and the regression suite exists because of it).

**The proof was a self-contained chain:** SD-Turbo painted a portrait in 2 seconds → that PNG went in as `reference_image` → an identity-held mp4 came out 310 seconds later, all through the operator API.

**Honest ceiling:** the operator's named quality bar is cloud-only (Nano Banana / Kling-class). The sovereign ceiling today is Wan 2.2 (photorealistic humans) + HunyuanVideo i2v (identity) + LTX (speed) + Flux (stills). HunyuanVideo *Avatar* — the audio-driven talking-avatar variant — needs a custom-node wrapper and is the documented next step, not a claimed capability.

## 6. Verify

```bash
ssh nephew-spark 'curl -s 127.0.0.1:8188/system_stats | head -c 120'          # expect comfyui_version
curl -s 127.0.0.1:8088/api/v1/video/health | jq '.pipeline.comfyui.ok'        # expect true (Mac)
ssh nephew-spark 'ls /mnt/nas-models/comfyui/diffusion_models/'               # vault holds the proven weights
```

## Related

- Ledger of record: `standard-video-stack/understandings/Super-Rick-Video-Stack-Ledger.md`
- [Chapter 31 — Inference floor](./31-m5-max-dgx-inference-setup.md) · [Chapter 32 — Hardware spec sheet](./32-hardware-full-spec-sheet.md)
