# Secret hygiene — no secret ever reaches git, on any repo

## The verbatim source (stated by Avery 2026-06-05)

> we have the proper .git files to hide important things? igone? … approved. proceed … mend them all

Said while standing up the Network Trust Spine, after an audit found `containers/.env.dgx` tracked and the `.gitignore` missing key/cert/tunnel patterns. The repo was private and the file held only benign config, but the *convention* would have auto-committed a real secret to four mirrors the day one landed.

## The rule

In **every** operator repo, secrets are kept out of git by **three** layers, not one:

1. **Ignore by pattern.** `.gitignore` ignores *all* env files and every key/cert/tunnel shape, while keeping `*.example` / `*.sample` templates tracked:
   ```gitignore
   .env
   .env.*
   *.env
   !*.env.example
   !.env*.example
   !.env*.sample
   *.key
   *.pem
   *.crt
   *.p12
   *.pfx
   id_rsa*
   id_ed25519*
   wg*.conf
   wireguard*.conf
   *-privkey*
   ca.key
   ```
2. **Block at commit.** A `.githooks/pre-commit` guard refuses to commit any secret-shaped file (catching the `git add -f` bypass of layer 1) and runs `gitleaks protect --staged` when gitleaks is installed. Wired repo-wide via `git config core.hooksPath .githooks`, enabled by `scripts/install-git-hooks.sh` (and a `make hooks` target).
3. **Block at push.** A `.githooks/pre-push` guard runs `gitleaks protect` over the range being pushed (when gitleaks is present) — the last line before a secret leaves the machine. (Honors the stack's no-GitHub-Actions rule: scanning is local, not CI.)

Every committed secret-bearing config gets an `<name>.example` twin with secret-named values blanked to `CHANGEME`, so a fresh clone knows what to fill.

## When this fires

- A new operator repo is created, or an existing one is audited.
- A `.env`, key, cert, or WireGuard config is introduced.
- Reviewing a PR that adds a config file — does it have an `.example` twin? Is the real file ignored?
- Onboarding a fresh machine — run `make hooks` (or `scripts/install-git-hooks.sh`) so the guard is active locally (`core.hooksPath` is per-clone, not committed).

## When this does NOT fire

- Deliberately-public artifacts (a CA *cert* meant to be shared) — force with `git add -f` and `git commit --no-verify`, documented in the PR.
- Pure-docs repos with no config files (the patterns are harmless there anyway).

## Why

`.gitignore` alone is necessary but not sufficient: it does nothing for an *already-tracked* file, and `git add -f` walks right past it. The commit + push guards close both holes, and they need no network or CI — they run on the machine, every time, for free.

## Propagation

Per [`rule-propagation-discipline`](rule-propagation-discipline.md): canonical body here (`nephew/.claude/rules/secret-hygiene.md`), mirrored to `.cursor/rules/secret-hygiene.mdc` and every operator repo's `.claude/` + `.cursor/`. The *implementation* (the `.gitignore` block, `.githooks/{pre-commit,pre-push}`, `scripts/install-git-hooks.sh`, `make hooks`) lands in each repo's own PR when adopted there.

## Related

- **Origin:** the Network Trust Spine work — [`docs/network-trust-spine.md`](../../docs/network-trust-spine.md) invariant 6 ("secrets stay on the DGX") and invariant 10 ("git, not drift").
- **Philosophy:** [`contracts-and-prudence`](contracts-and-prudence.md) — a leaked secret is the definition of careless; three cheap layers is the prudent default.
- **Sister rule:** [`rule-propagation-discipline`](rule-propagation-discipline.md) — how this lands on every surface.
