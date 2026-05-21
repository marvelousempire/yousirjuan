# One Tower, One URL — every new browser-facing UI embeds inside Nephew Control Tower

Binding rule for every agent operating in this repo. Mirrors **Universal Rule 15** in [`rules/GLOBAL-RULES-FOR-USING-NEPHEW.md`](../../rules/GLOBAL-RULES-FOR-USING-NEPHEW.md). Both must stay in sync.

---

## The contract

When you stand up any new app, dashboard, admin panel, or browser-facing UI for this platform, the default is to **embed it INSIDE the Nephew Control Tower** at `https://nephew.yousirjuan.ai/apps/<id>` via the apps-manifest pattern.

**Do NOT create a new subdomain by reflex.** The Tower is the single operator entrypoint; subdomains are the exception, not the default.

## Why

Every new subdomain is operational debt:

- New DNS A record to maintain
- New TLS cert to renew (and to remember to renew)
- New auth boundary (no shared session with the Tower)
- New cookie scope
- New bookmark for the operator
- New place for the operator to remember when they need to find a thing

The Tower model collapses N apps into one URL + N `/apps/<id>` routes. One nav. One auth. One cert. One bookmark.

## How to embed a new app

1. **Register in the manifest** — add an entry to `marvelousempire/nephew` → `data/control-tower-apps.manifest.json`:

   ```json
   {
     "id": "my-app",
     "label": "My App",
     "category": "agents",
     "subtitle": "What it does in one line",
     "embed_url": "https://my-app.yousirjuan.ai",
     "probe_url": "https://my-app.yousirjuan.ai/health",
     "external": true,
     "start_hint": "How to install / run / restore it",
     "route_key": "s-<11-random-chars>"
   }
   ```

2. **Strip `X-Frame-Options`** in the embedded app's nginx vhost so the iframe doesn't get blocked by `SAMEORIGIN`:

   ```
   proxy_hide_header X-Frame-Options;
   add_header Content-Security-Policy "frame-ancestors 'self' https://nephew.yousirjuan.ai https://*.yousirjuan.ai" always;
   ```

3. **Visit** `https://nephew.yousirjuan.ai/apps/my-app` — the `EmbedAppPage` renders the iframe with the Tower chrome around it.

## When a subdomain IS the right call

| Reason for separate subdomain | Example |
|---|---|
| Non-HTTP protocol on a dedicated port | `git.yousirjuan.ai:2424` (SSH for git) |
| Service explicitly serves third parties / public traffic | `hello.yousirjuan.ai` (public marketing page) |
| Service requires its own TLS termination logic (mTLS, custom alpn) | rare; document why in the PR body |
| Legacy app that predates the Tower model | grandfathered; don't migrate without operator request |
| Operator explicitly directs a subdomain | this rule defers to direct operator decision |

If none of the above applies: **embed in Tower.**

## Concrete examples

### ✅ Right

> Agent: "I'm adding Beszel monitoring."
> Agent reads `data/control-tower-apps.manifest.json`, sees the apps-manifest pattern, adds a `beszel` entry with `embed_url: https://beszel.yousirjuan.ai`, includes `X-Frame-Options` strip in the nginx vhost.
> Operator visits `https://nephew.yousirjuan.ai/apps/beszel` and sees it inside the Tower.

### ❌ Wrong (what happened on 2026-05-21)

> Agent shipped Uptime Kuma as `uptime.yousirjuan.ai` with no Tower integration. Operator's first reaction: *"can we just add that to the Control Tower which is the Nephew UI instead?"*
> Result: rework. The right move had been the manifest pattern from the start.

## ❌ FORBIDDEN

- Reflexively creating a new subdomain for a new web UI without considering the embed option
- Standing up a service whose only surface is its own subdomain when the apps-manifest pattern would fit
- Bypassing the manifest by hard-coding routes into the React app for one-off services
- Telling the operator "visit `https://newthing.yousirjuan.ai/`" when it could have been `https://nephew.yousirjuan.ai/apps/newthing`

## ✅ REQUIRED

- **Default** to the apps-manifest pattern for every new browser-facing UI
- When in doubt, ask the operator: "Embed in Tower (default) or separate subdomain (exception)?"
- Document the manifest entry + the `X-Frame-Options` strip + the nginx vhost as a single coordinated PR (or two coordinated PRs, one per repo, but ship them together)
- If a subdomain IS justified, write a one-paragraph note in the PR body explaining which exception applies and why

## Cross-references

- Universal Rule 15 in [`rules/GLOBAL-RULES-FOR-USING-NEPHEW.md`](../../rules/GLOBAL-RULES-FOR-USING-NEPHEW.md) — canonical authoritative version
- `marvelousempire/nephew` → `data/control-tower-apps.manifest.json` — the canonical apps registry
- `marvelousempire/nephew` → `apps/control-tower/src/pages/EmbedAppPage.tsx` — the renderer
- LEDGER-0016 in this repo — the original standalone Kuma subdomain that violated this rule
- LEDGER-0017 in this repo — the failed retrofit via sub-path routing (Kuma 1.x doesn't sub-path)
- `nephew` PR #27 — the embed-via-manifest fix that established the pattern this rule codifies
- `.claude/rules/contracts-and-prudence.md` — the operating philosophy this enforces: prefer consolidation over sprawl
