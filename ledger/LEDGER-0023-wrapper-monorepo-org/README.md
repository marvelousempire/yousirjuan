# LEDGER-0023 — Wrapper-Monorepo Organization (83 repos → 8 visible groupings)

**Status**: shipped (GitHub side). GitLab mirrors pending operator authorization.
**Started**: 2026-05-21
**Owner**: Avery
**Pattern**: extends [LEDGER-0021 private-parent submodule pattern](../LEDGER-0021-contribution-network-private-parent/) to all marvelous-empire repos.

## Origin (operator verbatim)

> "do we have now all of the GitHub repose I want to go ahead and bring them all down his lot more left so let's bring them all down so we can we organize everything and then push everything back up but I would do some folders so we expect the get a repo to look just like this repository when we're done organizing every thing"

Then a series of iterative grouping moves: ai-skills-library → control-tower; membadat → control-tower; brokerage-prototype, family-office-platform, briefcase-app → dashboards (later merged into consoles); scene-scout merged into scene-skout; bank-reader, crypto-reader, llm-reader, reader-console → consoles; json-archive-chat-reader → control-tower; contribution-network-private + cn-console → consoles; ContributionNetwork → standalone parent; PRIVATE renamed from skills; marketingskills, ruflo, claude-mem → ai-skills-library; dotclaude → archived (handled by historia).

## Problem

83 marvelous-empire repos lived flat on GitHub. There was no visible grouping — Quick Server cartridges were intermixed with Avery's businesses, with consoles, with the control tower. Hard to scan, hard to onboard a new contributor or agent, no top-level "table of contents."

## Solution

8 wrapper monorepos (LEDGER-0021 pattern) that submodule the leaf repos. Leaf repos remain authoritative — paths like `~/Developer/<repo>` and `start_hint` strings in [nephew/data/control-tower-apps.manifest.json](../../../../nephew/data/control-tower-apps.manifest.json) continue to work unchanged. The wrappers exist purely to give GitHub a navigable folder-equivalent view.

### Final taxonomy

| Wrapper | Submodules | Members |
|---|---|---|
| [tower-monorepo](https://github.com/marvelousempire/tower-monorepo) | 13 | yousirjuan · nephew · nephew-ai · nephew-meta-library · dustpan · bishop · automata · dockyard · clinic · historia · ai-skills-library · membadat · json-archive-chat-reader |
| [quick-server-monorepo](https://github.com/marvelousempire/quick-server-monorepo) | 25 | quick-server + 24 qs-* cartridges |
| [consoles-monorepo](https://github.com/marvelousempire/consoles-monorepo) | 15 | actions-, ai-, hive-, marketplace-, learnmappers-, sunday-console · bank-, crypto-, llm-, reader-console · contribution-network-private · cn-console · brokerage-prototype · family-office-platform · briefcase-app |
| [business-monorepo](https://github.com/marvelousempire/business-monorepo) | 5 | very-handy-man-services · daro-andy · briefcase-github-automation · LearnMappers · massillon-legal-site |
| [apps-monorepo](https://github.com/marvelousempire/apps-monorepo) | 12 | pockit · scene-skout · red-e-play-app · readyplay-marketing · SundayApp · Love-Art-Gallery-Tasks · iowre · slice-flows · bigbandwidth-revamp · big-6-pressure-plan-unit-418 · execution-hub-unit-418 · trustee-eyes-only-unit-418 |
| [infra-monorepo](https://github.com/marvelousempire/infra-monorepo) | 2 | gitlab-manager · iac-project |
| [writings-monorepo](https://github.com/marvelousempire/writings-monorepo) | 5 | architecture-of-truth · ArchitectureOfTruth · ConcisePerspective · yousirjuan-ai · series-handbook-framework |
| [ai-skills-library](https://github.com/marvelousempire/ai-skills-library) (sub-parent in tower) | 3 | marketingskills · ruflo · claude-mem |
| [contribution-network-private](https://github.com/marvelousempire/contribution-network-private) (standalone parent, also submodule of consoles) | 1 | ContributionNetwork |

77 leaves total grouped under 8 visible top-level structures. ai-skills-library is a nested sub-parent (inside tower-monorepo).

### Archived (not deleted — `gh` token lacks `delete_repo` scope)

- **scene-scout** — merged into scene-skout. Unique React UI/UX docs preserved at [scene-skout/docs/legacy-from-scene-scout/](https://github.com/marvelousempire/scene-skout/tree/main/docs/legacy-from-scene-scout).
- **dotclaude** — coverage by [historia](../../../../historia) (which ingests Claude/Cursor plans + skills + rules). Local `~/Developer/dotclaude/` left untouched.

To hard-delete instead of archive:
```
gh auth refresh -s delete_repo && gh repo delete marvelousempire/scene-scout --yes
gh auth refresh -s delete_repo && gh repo delete marvelousempire/dotclaude --yes
```

## Reversibility

- Each wrapper is a thin metadata repo (.gitmodules + README + submodule pointers). No code lives inside.
- Deleting a wrapper deletes nothing in the leaf repos.
- Reverting an archive on scene-scout/dotclaude: `gh repo edit <name> --visibility private` (re-unarchive) — content is preserved.
- The local layout under `~/Developer/` was not touched. Every leaf is still at `~/Developer/<repo>/`. The wrappers live in `~/Developer/_monorepos/<wrapper>/`.

## What this does NOT do

- Does not move physical leaf folders on disk. `~/Developer/<repo>` paths are unchanged.
- Does not touch `start_hint` lines in nephew apps-manifest or any other script that hardcodes `~/Developer/<repo>`.
- Does not change visibility on any leaf repo.
- Does not rename any leaf repo.

## Pending follow-ups

1. **GitLab mirrors** — none of the 8 new wrappers have a `gitlab` remote yet. The session auto-classifier blocked the first push attempt at `ssh://git@72.167.151.251:2424/...` (raw-IP destination not in trusted hosts). Operator decision needed on:
   - Allow the IP-based GitLab destination for this session (add to settings as a permission)
   - Or use the Tailscale hostname (`vps-godaddy`) — if classifier accepts that
   - Or skip GitLab mirror for the wrappers (GitHub-only, since wrappers are thin metadata)
2. **DustPan main divergence** between GitHub (`a0176a2`) and GitLab (`33cb092`) — same logical "binder metadata seed" commit committed twice with different SHAs. Three options:
   - Force-push GitHub → GitLab (overwrites GitLab's binder SHA; safe since the content is the same)
   - Merge GitLab into GitHub (preserves both SHAs in history; adds a merge commit)
   - Reset GitLab to GitHub's main (destructive on GitLab side)
3. **Hard-delete vs archive** for scene-scout and dotclaude — depends on whether operator wants the repos fully gone or kept read-only.

## Verification

```bash
# All 7 new wrappers present on GitHub
for w in tower quick-server consoles business apps infra writings; do
  gh repo view marvelousempire/${w}-monorepo --json url,visibility,defaultBranchRef --jq '"\(.url)  \(.visibility)  \(.defaultBranchRef.name)"'
done

# Local wrappers populated with submodules
for w in tower quick-server consoles business apps infra writings; do
  echo "${w}-monorepo: $(git -C ~/Developer/_monorepos/${w}-monorepo submodule status | wc -l | tr -d ' ') submodules"
done

# A leaf repo (yousirjuan) is unchanged at its original location
ls ~/Developer/yousirjuan/.git >/dev/null && echo "leaf preserved"

# Nephew start_hint paths still resolve
python3 -c "
import json, os
m = json.load(open('/Users/averygoodman/Developer/nephew/data/control-tower-apps.manifest.json'))
for app in m['apps']:
    h = app.get('start_hint','')
    if 'Developer/' in h:
        path = h.split('cd ')[-1].split(' ')[0] if 'cd ' in h else ''
        if path:
            ok = os.path.isdir(os.path.expanduser(path))
            print(f'{\"OK \" if ok else \"BAD\"}  {app[\"id\"]:25}  {path}')
"
```

## Related

- Pattern source: [LEDGER-0021](../LEDGER-0021-contribution-network-private-parent/)
- CI for wrappers (future): pattern from [LEDGER-0022](../LEDGER-0022-cn-contract-checks/)
- Operator philosophy: `.claude/rules/contracts-and-prudence.md`
- Naming and grouping decisions came from iterative operator feedback during the same 2026-05-21 session
