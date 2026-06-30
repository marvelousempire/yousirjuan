# Capability-matched fleet offload — reserve the DGX, work every node (RL-FLEET-OFFLOAD-001)

## The verbatim source (stated by Avery 2026-06-30)

> always figure out how best you can modify onemac and twomac and zeromac and NAS to
> your best to give them the works they can handle to take workloads off DGX. Core rule
> establishment.

Captured as **INT-0032 `#fleet-capability-offload`** in `data/intent-ledger.json`.

## The rule (permanent, every AI surface)

The **DGX Spark (GB10, 121 GB unified)** is the family's scarce, precious GPU brain.
**Reserve it for the work that only it can do** — large-LLM reasoning, GPU voice/TTS
synthesis, anything needing more GPU memory than a Mac/NAS has. **Everything else is
offloaded.** For every other family node — `onemac`, `twomac`, `zeromac`, `bigmac`, the
**NAS (UGREEN DXP6800 Pro)** — you must **continuously assess what it can handle, actively
provision it, and route that work onto it to relieve the DGX.**

This is **two duties, not one**:

1. **Assess + route** — match each workload to the cheapest node that can run it well.
2. **Provision (modify) the node** — it is *not enough* to route; you **set the node up** so
   it *can* take the work (install the toolchain, mount the model cache, stand up the
   service, fix reachability). A reachable node sitting idle because nobody provisioned it
   is a violation. "Give them the works they can handle" means **make them able**, then
   give it.

The DGX is relieved by **moving off it everything that does not need the GB10.** When the
DGX is under pressure, the first question is never "buy more GPU" — it is **"which node
should be doing this instead, and is it provisioned?"**

### Workload → node capability matrix (the default routing)

| Workload | Best home | Why |
|----------|-----------|-----|
| Large-LLM reasoning (≥30B, FP8/heavy) | **DGX only** | needs the GB10 |
| GPU voice/TTS synthesis (Higgs Audio, etc.) | **DGX only** | needs the GPU |
| **Query embedding** (bge-m3) | **Mac (ANE/MPS)** / NAS CPU | tiny model; keeps it always-warm off the contended GPU |
| **Reranking** (cross-encoder) | **a capable Mac (ANE/MPS)** | small but eviction-prone on the DGX — pin it to a Mac so it never gets paged out |
| **STT / Whisper** | **Mac ANE** (MacWhisper, INT-0029) | the ANE is ideal; frees the DGX |
| Small/quantized LLM, intent-classify, harvest-score | **Mac (MLX/ollama)** | doesn't need 30B |
| Batch indexing, embeddings-at-rest, background jobs | **NAS CPU / idle Mac** | latency-insensitive |
| Model cache / cold storage | **NAS (DXP6800)** | the family model vault ([[family-model-cache-no-redownload]]) |

The living per-node registry is **`data/fleet-node-capabilities.json`** — assess on
discovery, record hardware + what the node can handle + provisioned yes/no, and keep it
current.

### Node reality (2026-06-30 snapshot — keep updated)

- **DGX** (`nephew-spark`, GB10/121 GB) — central brain; reserve for big-LLM + GPU voice.
- **onemac** (M1, 8 GB) — embeddings + STT on the ANE; **too small for the reranker**.
- **bigmac** — strongest Mac offload candidate (assess + provision when on LAN/WG).
- **twomac / zeromac** — assess on contact (twomac's WG was down + host key changed; zeromac offline at probe). **Fix reachability as part of provisioning.**
- **NAS DXP6800 Pro** (`nasa.local` / `192.168.10.119`, Intel CPU, no GPU) — model cache,
  CPU embedding, batch jobs; **not** the cross-encoder.

## When this fires

- **Any time the DGX is under memory/compute pressure** (e.g. the 2026-06-30 RAG audit: the
  reranker was evicted because the GB10 was memory-pinned — the structural answer is offload
  the small sidecars to a Mac so they never compete).
- A **new node** joins, or an existing node's reachability/specs change.
- A **new workload type** appears — pick its node by the matrix, not "put it on the DGX."
- Capacity planning, or "should we buy more GPU?" — first exhaust fleet offload.

## When this does NOT fire

- Work that genuinely needs the GB10 (large-LLM reasoning, GPU TTS) — stays on the DGX.
- A node that is genuinely incapable (e.g. the cross-encoder on a CPU-only NAS) — don't
  route work a node can't run *well*; provision a capable node instead.

## Forbidden

- Leaving a reachable node **idle/unprovisioned** while the DGX is under pressure.
- Routing **GB10-class** work to a node that can't handle it (forcing CPU fallback /
  swap — that's worse than the DGX).
- Treating offload as **routing-only** — not setting the node up so it *can* take the work.
- Answering DGX pressure with "buy more hardware" before exhausting the fleet.

## Examples

### ✓ Compliant

The DGX reranker keeps getting evicted under memory pressure → **provision `bigmac`** with
the cross-encoder (MLX/sentence-transformers + bge-reranker from the family model cache),
point `RERANKER_URL` at it, and the reranker is now **always warm off the GB10** — cross-encoder
quality returns and the DGX gets ~3 GB + a slot back.

### ✗ Violation

"The DGX is memory-pressured, the reranker is slow" → leave `onemac`/`bigmac` idle and just
raise a timeout. (Offload the sidecar; don't paper the symptom.)

## Sovereignty bound

All offload stays on **family-owned hardware** ([[prefer-family-office-terminology]],
`docs/sovereign.md`). Offload never reaches for a rented VPS or vendor inference API.

## Self-heal bound

Provisioning + routing should be **ensure-able** ([[structural-self-heal-smart-technology]]
RL-SMART-001): a node's offload role boots/heals itself, and the agent runs the ensure — it
does not hand the operator a paste block.

## Propagation

Per [[rule-propagation-discipline]]: canonical here; mirror to
`.cursor/rules/fleet-capability-offload.mdc`, `.nephew/rules/`, `data/nephew-soul.md`
operating rules, the **You-Sir Juan handbook** (`yousirjuan/.claude/rules/` +
`yousirjuan/.cursor/rules/` — the canonical hardware/inference setup repo), global
`~/.claude/CLAUDE.md` / operator memory, and the AI Skills Library rule pack.

## Related

- [[structural-self-heal-smart-technology]] (RL-SMART-001) — ensure-able offload, no paste blocks
- [[family-model-cache-no-redownload]] (RL-MODELCACHE-001) — the NAS model vault offload shares from
- [[multi-agent-coordination]] (RL-MULTIAGENT-001) — fleet awareness
- [[prefer-family-office-terminology]] — family hardware first, internet/vendor last
- **Inference floor:** `yousirjuan/docs/setup/31-m5-max-dgx-inference-setup.md` (Mac-first routing, weigh-and-measure)
- **Registry:** `data/fleet-node-capabilities.json` · `data/fleet-mac-hosts.local.json` · `data/hardware-inventory.json`
- **Intent:** INT-0032 `#fleet-capability-offload`
