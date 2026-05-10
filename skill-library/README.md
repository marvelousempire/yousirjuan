# Skill Library

This directory is the new home for the private AI skills library formerly maintained at:

`marvelousempire/ai-skills-library`

The goal is to consolidate the skills catalog into `marvelousempire/yousirjuan` so You-Sir Juan™ becomes the canonical sovereign AI infrastructure repo for:

- local AI skills
- Cursor skills
- Claude Code skills
- external tool bridge skills
- marketing skills
- product context
- agent operating notes
- rules and skill-generation workflows

---

## Migration Status

Initial migration pass completed through the GitHub connector.

Imported into this directory:

- root skill library overview
- agent operating notes
- skill index
- skills taxonomy
- marketing skill catalog
- external bridge skill catalog
- migration notes

Known limitation of this migration pass:

- the connector exposed file-by-file access, not a recursive repository export operation
- the complete 68-skill tree should be mirrored from the original repo before deleting `marvelousempire/ai-skills-library`
- until the full tree is verified, do not delete the original repository

---

## Canonical Destination

Going forward, the skill library should live here:

```text
marvelousempire/yousirjuan/skill-library/
```

Expected final structure:

```text
skill-library/
  README.md
  AGENTS.md
  SKILL-INDEX.md
  THIRD_PARTY.md
  context/
  docs/
  rules/
  scripts/
  skills/
    marketing/
    ide/cursor/
    visual/design/
    project/red-e-play/
    external/
```

---

## Required Follow-Up Before Deleting Old Repo

Before deleting `marvelousempire/ai-skills-library`, verify that `skill-library/` contains:

- all 68 `SKILL.md` files
- all catalogs
- all docs
- all scripts
- all rules
- all context files
- all license / attribution files

Run a local mirror command from a trusted workstation:

```bash
cd ~/Developer/yousirjuan
mkdir -p skill-library
rsync -a --delete ~/Developer/ai-skills-library/ ./skill-library/
git add skill-library
git commit -m "Import ai skills library into yousirjuan"
git push
```

After that verification, the standalone `ai-skills-library` repo can be retired.
