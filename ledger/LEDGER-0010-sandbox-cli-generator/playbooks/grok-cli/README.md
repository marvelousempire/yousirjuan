# Sandbox: grok-cli

xAI's Grok CLI Beta, sandboxed per ADR-0001.

## Why sandboxed

- **Untrusted by default** — third-party CLI making outbound LLM API calls
- **Native-deps tree** — Node + npm install of `@x-ai/grok-cli` brings in dependencies we'd rather not pollute the host with

## First-time setup

1. Get an xAI / Grok API key from https://x.ai/api (operator does this manually — not automatable).
2. Stash it on the host (NEVER committed):

   ```bash
   mkdir -p ~/sandbox-workspaces/grok-cli && \
   chmod 700 ~/sandbox-workspaces/grok-cli && \
   cat > ~/sandbox-workspaces/grok-cli/.env <<'EOF'
   GROK_API_KEY=xai-paste-key-here
   EOF
   chmod 600 ~/sandbox-workspaces/grok-cli/.env
   ```

3. Build and run:

   ```bash
   cd ~/Developer/yousirjuan/ledger/LEDGER-0010-sandbox-cli-generator/playbooks && \
   make build tool=grok-cli && \
   make run   tool=grok-cli
   ```

4. Inside the container:

   ```bash
   grok --help          # confirm CLI present
   grok "hello"         # first real call; uses GROK_API_KEY from .env
   ```

## Daily usage

```bash
make -C ~/Developer/yousirjuan/ledger/LEDGER-0010-sandbox-cli-generator/playbooks run tool=grok-cli
```

Inside the container, `/workspace` is your scratch dir (persists across runs).
Outside `/workspace`, the container can't see anything on your host.

## Updating Grok CLI

When xAI ships a new version:

```bash
make -C ~/Developer/yousirjuan/ledger/LEDGER-0010-sandbox-cli-generator/playbooks build tool=grok-cli
```

(Forces a rebuild → fresh `npm install -g @x-ai/grok-cli`.)

## Removing

```bash
cd ~/Developer/yousirjuan/ledger/LEDGER-0010-sandbox-cli-generator/playbooks && \
make stop tool=grok-cli && \
make rm   tool=grok-cli && \
rm -rf ~/sandbox-workspaces/grok-cli
```

## Caveat about the install command

The Dockerfile's `npm install -g @x-ai/grok-cli` is best-guess based on
publicly available info as of 2026-05-20. xAI's actual distribution channel
may differ (homebrew, standalone binary, different npm package name). If the
build fails on that line, update the Dockerfile with the current install
method per https://docs.x.ai/ and re-run `make build tool=grok-cli`.
