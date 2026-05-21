---
ledgerId: LEDGER-0021
title: Contribution Network — private parent + public submodule pattern (template for future pairs)
status: shipped
opened: 2026-05-21
closed: 2026-05-21
related-tickets: []
triggers:
  - manual: this pattern, not a recurring trigger
---

# LEDGER-0021 — Private-parent + public-submodule pattern (Contribution Network)

## Ask

Operator 2026-05-21 surfaced a detailed argument for using git submodules to wire a private parent to a public child repo (6 benefits: versioned linkage, one-clone setup, atomic cross-repo commits, single working directory, CI sees both sides, permission isolation). Asked: *"did we do this with the Contribution Network?"*

Answer was no — ContributionNetwork existed as a standalone public repo at `marvelousempire/ContributionNetwork` with no private parent. This LEDGER establishes the pattern + ships the first instance.

## Outcome (shipped)

New private repo: **[`marvelousempire/contribution-network-private`](https://github.com/marvelousempire/contribution-network-private)**.

Contents:
- `README.md` documenting the pattern, layout, clone semantics, and how to bump the framework version
- `.gitmodules` pinning `marvelousempire/ContributionNetwork` at the init commit
- `contribution-network/` — submodule containing the public framework as it was at init
- `private/` — default-gitignored scratch dir for operator-only content (use `git add -f` to commit specific files)

Both repos remain separate; the link is the submodule pointer.

## The 6 benefits (operator's framing)

1. **Versioned linkage** — parent records the exact public-framework commit it expects. "Private deployment v2.3" always points at "framework as it looked on May 18." Two unrelated repos drift apart over time; submodules don't.

2. **One-clone setup** — `git clone --recurse-submodules https://github.com/marvelousempire/contribution-network-private.git` gets both. New collaborator onboarding is one command.

3. **Atomic-ish cross-repo commits** — change the public framework, push there, bump the submodule pointer in the parent + add a private change in one parent commit. Single recorded logical step.

4. **Single working directory** — `cd contribution-network-private && grep -r ...` searches both at once. Portable: works on any machine that clones (unlike a symlink that lives only on one machine).

5. **CI sees both** — any CI job in the private repo gets the public framework checked out too. Cross-repo checks become trivial.

6. **Permission isolation** — pointer is just a SHA + URL. The private repo leaks nothing about the public framework's content (already public), and the public framework has no idea it's submoduled. Read-access to the private parent grants no extra read-access to public content (you already had it).

## Honest downside

Submodules have a reputation for friction: people forget `--recurse-submodules`, the pointer goes stale, `git status` shows confusing "modified" state. For a solo operator with two repos this is manageable. The README in the private parent has the right-way commands at the top so they're always one paste away.

## Replay (zero-AI, on a new machine)

```bash
# Clone the private parent with public child in one go
git clone --recurse-submodules https://github.com/marvelousempire/contribution-network-private.git
cd contribution-network-private

# That's it. contribution-network/ has the public framework. private/ is yours.
```

To bump the framework version later:

```bash
cd contribution-network/
git fetch && git checkout origin/main  # or any commit/tag you want to pin
cd ..
git add contribution-network
git commit -m "bump: framework → $(cd contribution-network && git rev-parse --short HEAD)"
bash /Users/averygoodman/Developer/yousirjuan/tools/git-dual-push.sh main
```

## When to use this pattern (template for future pairs)

Use private parent + public submodule when:

- The framework / library / content is genuinely useful publicly AND
- Operator wants to keep deployment specifics / proprietary config / private notes out of the public eye AND
- Versioned linkage matters (you want "version X of my deployment uses framework commit Y" to be recorded)

Don't use this pattern when:

- The relationship is one-way "I use this library" — use a regular dependency (npm/pip/cargo/go.mod)
- The two repos are both fully public or both fully private (no isolation gained)
- The framework changes daily and you don't want version-pinning friction — just `git submodule update --remote` periodically OR don't submodule at all

## Cross-references

- New repo: `marvelousempire/contribution-network-private` (private, just created)
- Public child: `marvelousempire/ContributionNetwork` (unchanged; now has a private parent it doesn't know about)
- Pattern source: operator's analysis quoted verbatim in this LEDGER's README

## Open follow-ups

- **VPS deployment** of the private parent (operator's call — when needed, `git clone --recurse-submodules` on VPS + integrate with whatever uses the framework there). Currently the public framework lives at `/opt/ContributionNetwork/` and `/home/abrownsanta/ContributionNetwork/`; neither is the private parent. Operator decides whether to add a private-parent clone alongside, OR migrate to using the parent as the deployment root.
- **CI job** in the private parent that runs cross-repo checks (e.g. "does this private deploy still align with the public framework's contracts?"). Future PR.
