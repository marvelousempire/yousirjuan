# You-Sir Juan OS — Intel Mac Installer

One-liner setup for iMac (2017 Intel), MacBook (Intel), or Mac mini (Intel) running macOS Ventura 13+.

## The one line

```bash
curl -fsSL https://get.yousirjuan.ai/intel-mac | sh
```

Or directly from GitHub Releases:

```bash
curl -fsSL https://github.com/marvelousempire/yousirjuan-ai/releases/latest/download/install-intel-mac.sh | sh
```

Or from inside the repo:

```bash
bash installers/intel-mac/install.sh
```

---

## What it installs

| Step | What happens |
|---|---|
| Homebrew | Installed if missing |
| Git | Installed via Homebrew if missing |
| Node.js 20 | Installed via nvm if missing |
| pnpm | Installed if missing |
| Docker Desktop | Guided download if missing (Intel chip version) |
| Ollama | Installed (Intel x86_64 build) |
| You-Sir Juan repo | Cloned to `~/yousirjuan` |
| `.env` | Written with Intel Mac-optimized defaults |
| Docker services | `postgres`, `redis`, `qdrant`, `ollama`, `kokoro` started |
| `llama3.2:3b` | Pulled via Ollama (~2 GB) |
| LaunchAgent | API auto-starts on login |
| Web interface | Opens `http://localhost:3000` in browser |

**Total install time:** ~15–30 min (mostly model download)

---

## After install

| Service | URL |
|---|---|
| Family interface (web) | http://localhost:3000 |
| API | http://localhost:4000 |
| Ollama | http://localhost:11434 |

Walk up to the browser, pick your family member, and step into their world.

**Voice turns** use `llama3.2:3b` by default — 8–15 tokens/sec on Intel i5, fast enough for 2–4 second voice responses.

---

## Want iOS 18 development capability?

The 2017 iMac with Ventura is capped at Xcode 15, which cannot build iPadOS 18 targets. OpenCore Legacy Patcher upgrades the machine to Sonoma → Xcode 16 → full iOS 18 + visionOS 2 development.

**Guide:** [`opencore-sonoma-guide.md`](./opencore-sonoma-guide.md)

Or visit: `https://get.yousirjuan.ai/intel-mac/guide`

---

## Hardware compatibility

| Machine | RAM | Status |
|---|---|---|
| iMac 21.5" 2017 (i5, 64 GB) | 64 GB | ✅ Excellent (primary target) |
| iMac 21.5" 2017 (i5, 16 GB) | 16 GB | ✅ Good — use `llama3.2:3b` |
| iMac 21.5" 2017 (i5, 8 GB) | 8 GB | ⚠️ Minimal — backend runs, inference slow |
| iMac 27" 2017–2020 (i5/i7) | 16–64 GB | ✅ Excellent |
| MacBook Pro 2017–2019 (Intel) | 16 GB | ✅ Good |
| Mac mini 2018 (Intel) | 16–64 GB | ✅ Good |

Full capability matrix: [`docs/hardware/imac-2017-intel-i5.md`](../../docs/hardware/imac-2017-intel-i5.md)

---

## Verify the installer checksum

```bash
curl -fsSL https://get.yousirjuan.ai/intel-mac/sha256
# Then compare against the downloaded file:
sha256sum install-intel-mac.sh
```
