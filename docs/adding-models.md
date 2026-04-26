# Adding language models

Everything Ollama-compatible from the official catalog at https://ollama.com/library works.

## Pull a model

On any machine running Ollama (your VPS, M1, iMac):

```bash
ollama pull qwen3:8b
ollama pull llama3:8b
ollama pull gpt-oss:20b
```

Once pulled, the model **automatically appears** in Open WebUI's model dropdown — no Open WebUI config change needed.

## Recommended catalog (by RAM)

| Model | Pull command | Size | Min RAM | Best for |
|---|---|---|---|---|
| **gemma2:2b** | `ollama pull gemma2:2b` | 1.6 GB | 4 GB | Fastest; quick chat; phone over tailnet |
| **llama3.2:3b** | `ollama pull llama3.2:3b` | 2.0 GB | 4 GB | Balanced default; fast on any hardware |
| **llama3:8b** | `ollama pull llama3:8b` | 4.7 GB | 16 GB | Meta's general-purpose 8B; great everyday quality |
| **qwen3:8b** | `ollama pull qwen3:8b` | 5.0 GB | 16 GB | Alibaba's latest; strong code + reasoning |
| **gpt-oss:20b** | `ollama pull gpt-oss:20b` | 13 GB | 32 GB | OpenAI's open-weights; flagship-class quality |
| **gemma4:26b** | `ollama pull gemma4:26b` | 16 GB | 32 GB | Google's latest flagship; very strong general reasoning |
| **qwen3:14b** | `ollama pull qwen3:14b` | 9 GB | 32 GB | Better reasoning, mid-size |
| **gemma4:31b** | `ollama pull gemma4:31b` | 19 GB | 40 GB | Bigger gemma4 variant |
| **gpt-oss:120b** | `ollama pull gpt-oss:120b` | 65 GB | 96 GB | Top-tier — needs serious hardware |
| **llama3.1:70b** | `ollama pull llama3.1:70b` | 40 GB | 64 GB | Meta's flagship — needs M1 Max/Ultra or NVIDIA GPU |
| **deepseek-coder:6.7b** | `ollama pull deepseek-coder:6.7b` | 3.8 GB | 8 GB | Code-specialized |
| **phi3:medium** | `ollama pull phi3:medium` | 7.9 GB | 16 GB | Microsoft's compact reasoning model |
| **mistral:7b** | `ollama pull mistral:7b` | 4.1 GB | 8 GB | Fast, decent quality |
| **llava:13b** | `ollama pull llava:13b` | 8 GB | 16 GB | **Vision** — can read images you upload |
| **nomic-embed-text** | `ollama pull nomic-embed-text` | 274 MB | 1 GB | Embedding model for RAG (Open WebUI uses this for knowledge bases) |

## Where they're stored

Set during install via `MODELS_DIR` env var or interactive prompt. Defaults:
- macOS / Linux: `~/.ollama/models`
- VPS (we set explicitly via systemd override): see `/etc/systemd/system/ollama.service.d/override.conf`

To check:
```bash
launchctl getenv OLLAMA_MODELS    # macOS
systemctl cat ollama | grep MODELS # Linux
```

## Free disk space

```bash
ollama list                   # see what's installed + sizes
ollama rm <model_name>        # remove one
du -sh ~/.ollama/models       # total disk usage (or wherever OLLAMA_MODELS points)
```

## Privacy

- Pull = HTTPS download from `ollama.com` CDN. They know your IP downloaded model X. They see **zero** of your inference data.
- Inference = 100% local on your hardware. **No traffic leaves your machine.**
- Models are GGUF — open weights, no embedded telemetry. Inspectable.
- If paranoid: download once on a machine, transfer the model files to your air-gapped real machine via USB.

## Modify models (parameters + system prompts)

Without re-training, you can customize a model's behavior using Ollama's Modelfile syntax. See [`modelfile-customization.md`](modelfile-customization.md).

## Train models (real fine-tuning)

Different beast — bakes new knowledge into the weights. Requires GPU (M1 works, NVIDIA much faster), hours of compute, training data. Out of scope for this repo today; doable as a separate project. Tools: Unsloth, Axolotl, LoRA. Output is a new GGUF you import via Modelfile + `ollama create`.

For most family-office use cases (documents, contracts, policies) **RAG is the right tool, not fine-tuning** — see [`rag-and-knowledge.md`](rag-and-knowledge.md).
