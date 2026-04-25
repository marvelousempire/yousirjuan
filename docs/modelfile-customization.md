# Modelfile customization

Tweak a model's personality, parameters, and behavior **without re-training** — using Ollama's Modelfile syntax. 5 minutes per custom model.

## What you can change

| Directive | Effect |
|---|---|
| `FROM <model>` | Base model (any installed Ollama model) |
| `SYSTEM "..."` | The system prompt (the model's "personality") |
| `PARAMETER temperature 0.3` | Sampling temperature (0.0 = deterministic, 1.0 = creative) |
| `PARAMETER num_ctx 32768` | Context window (in tokens) |
| `PARAMETER top_k 50` | Sample from top K candidates |
| `PARAMETER top_p 0.9` | Nucleus sampling |
| `PARAMETER repeat_penalty 1.2` | Penalize repeated tokens |
| `PARAMETER num_predict 2048` | Max tokens to generate |
| `MESSAGE user "..."` / `MESSAGE assistant "..."` | Pre-load few-shot examples |
| `TEMPLATE "..."` | Override the prompt template (advanced) |

Full reference: https://github.com/ollama/ollama/blob/main/docs/modelfile.md

## Example 1 — family office assistant

Create a file `Modelfile-yousirjuan`:

```
FROM llama3:8b

PARAMETER temperature 0.3
PARAMETER num_ctx 32768
PARAMETER repeat_penalty 1.15

SYSTEM """
You are the You-Sir Juan family office AI assistant.

Tone: concise, professional, direct. No throat-clearing ("Of course!" / "I'd be happy to..."). No filler.

Rules:
- When asked about financials, always cite the source document name and page if available.
- Never speculate without saying so explicitly.
- If asked something that requires real-time data (today's market price, news), say so plainly — don't guess.
- Default to bullet lists for procedural answers; prose for analytical ones.
- US English. Don't switch languages unless explicitly asked.
"""
```

Build it:
```bash
ollama create yousirjuan-assistant -f Modelfile-yousirjuan
```

Now `yousirjuan-assistant` shows up in `ollama list` AND in Open WebUI's model dropdown.

## Example 2 — concise coding model

```
FROM qwen3:8b

PARAMETER temperature 0.1
PARAMETER num_ctx 16384

SYSTEM """
You are a senior engineer. Reply with code, minimal commentary. If a question
is ambiguous, ask once for clarification then answer. If giving multiple options,
list trade-offs in 1 line each. Never explain code that is self-evident.
"""
```

```bash
ollama create yousirjuan-engineer -f Modelfile-engineer
```

## Example 3 — kid-friendly explainer (for family members under 18)

```
FROM llama3:8b

PARAMETER temperature 0.7

SYSTEM """
You are a patient teacher explaining to a curious 12-year-old.
Use simple analogies. Avoid jargon. If you must use a technical word, define it
the first time. Encourage follow-up questions. Never refuse a topic for being
too complex — break it down instead.
"""
```

```bash
ollama create yousirjuan-explainer -f Modelfile-kids
```

## Why use these instead of changing system prompt in Open WebUI's UI?

You CAN do all this via Open WebUI's UI under **Workspace → Models → Create**. Modelfiles are useful when:
- You want the same custom model on multiple machines (just `scp` the Modelfile + `ollama create` on each)
- You want the customization version-controlled (commit the Modelfile to this repo)
- You want it baked into Ollama (so other tools that hit Ollama directly, like OpenClaw, get the customized version too)

## Combining with RAG

Modelfile + Knowledge Base = the full custom assistant. Workflow:

1. Create the Modelfile with system prompt + parameters
2. `ollama create my-model -f Modelfile`
3. In Open WebUI, **Workspace → Models → Create** with `my-model` as the base
4. Attach a knowledge base
5. Save — it inherits the Modelfile's system prompt PLUS gets the RAG context

## Versioning

Commit your Modelfiles to this repo under `config/modelfiles/`. Then deploy with:

```bash
for mf in config/modelfiles/Modelfile-*; do
  name=$(basename "$mf" | sed 's/Modelfile-//')
  ollama create "yousirjuan-$name" -f "$mf"
done
```

This ensures every machine in your stack ends up with the same custom models.
