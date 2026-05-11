# AI Skills Library (submodule)

This repo vendors **[`marvelousempire/ai-skills-library`](https://github.com/marvelousempire/ai-skills-library)** at:

`vendor/ai-skills-library/`

That private library holds **Cursor/Claude agent skills**, **generated external-tool bridge skills**, **canonical rules** (codegen to `.cursor`/`.claude`), and sync scripts. It is the **single source of truth**; do not duplicate `skills/` or `rules/` trees elsewhere.

## Clone with submodules

```bash
git clone --recurse-submodules https://github.com/marvelousempire/yousirjuan.git
# or after a normal clone:
git submodule update --init --recursive
```

## Bump the library

```bash
cd vendor/ai-skills-library && git fetch origin && git checkout main && git pull
cd ../..
git add vendor/ai-skills-library
git commit -m "chore: bump ai-skills-library submodule"
```

## Wire skills / rules on a dev machine

From `vendor/ai-skills-library/` (after submodule init):

```bash
./scripts/link-external-skills-to-claude.sh
```

To flatten skills into **this** repo’s Cursor project layout (optional):

```bash
./scripts/install-repo-skills-to-cursor-project.sh "$(git rev-parse --show-toplevel)"
```

To emit shared **rules** into this repo (optional; Red-E Play–style packs by default):

```bash
./scripts/sync-rules-into-repo.sh "$(git rev-parse --show-toplevel)"
```

Full detail: upstream doc [`consuming-from-other-private-repos`](https://github.com/marvelousempire/ai-skills-library/blob/main/docs/consuming-from-other-private-repos.md).

## Related: native iOS cinematic / 3D PRD (this repo)

For a **product-level spec** that pairs AI-assisted UI work (including UI/UX Pro Max–style prompts) with **SwiftUI + RealityKit** “RealityMotion” language, see:

- [`realitymotion-premium-cinematic-3d-ios-prd.md`](realitymotion-premium-cinematic-3d-ios-prd.md)
