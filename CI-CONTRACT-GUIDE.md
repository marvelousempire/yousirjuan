# Contract Versioning & CI Enforcement Guide

## How the Contract is Versioned

### Version Format

```
Contract Version: 1.0.0
Contract Hash: YSJ-NEPHEW-CONTRACT-v1.0.0
```

**Versioning Scheme:**
- **Major (1.x.x)**: Breaking changes to repo boundaries (e.g., moving a whole category from one repo to another)
- **Minor (x.1.x)**: Adding new categories to the contract (e.g., adding "frameworks" to Nephew)
- **Patch (x.x.1)**: Clarifications, typo fixes, documentation updates

**Contract Hash:** Unique identifier combining repo names and version for CI validation

---

## How CI Enforces the Contract

### 1. Contract Version Metadata (in REPOS-CONTRACT.md)

```markdown
**Contract Version:** `1.0.0`
**Contract Hash:** `YSJ-NEPHEW-CONTRACT-v1.0.0`
**CI Enforcement:** ✅ Active

## Version History
| Version | Date | Changes |
|---|---|---|
| 1.0.0 | May 16, 2026 | Initial contract |```

**CI checks this in `contract-sync-check.yml`:**
- ✅ REPOS-CONTRACT.md exists
- ✅ Contract has required sections (Core Identity, What Lives Where, Clear Boundaries, How They Work Together)
- ✅ Contract has version number
- ✅ Contract has hash

---

### 2. Content Enforcement CI Checks

#### You-Sir Juan: `contract-enforcement-no-persona.yml`

**What it blocks:** PRs containing persona/interface content

**Checks:**
```bash
# Check 1: Associate Agent definitions
grep -r "Associate Agent" --include="*.md" . | grep -v "REPOS-CONTRACT"
# Fails if found

# Check 2: Persona table (Member | Associate | Palette | Character)
grep -r "Member.*Associate.*Palette.*Character" --include="*.md" . | grep -v "REPOS-CONTRACT"
# Fails if found

# Check 3: All four personas defined together
grep -l "Sterling" . | xargs grep -l "Blake" | xargs grep -l "Cipher" | xargs grep -l "Full"
# Fails if all four appear in same file (signature of persona table)

# Check 4: Interface UX (Walk-Up Kiosk, Biometric, Voice-First)
grep -r "Walk-Up Kiosk\|Biometric Authentication\|Voice-First" --include="*.md" .
# Fails if found

# Check 5: Family member onboarding
grep -r "family member is provisioned\|new member is provisioned" --include="*.md" .
# Fails if found

# Check 6: Meta-library content
grep -r "meta-library\|compounding brain" --include="*.md" .
# Fails if found
```

**Why this works:** The check looks for **patterns unique to personas** (Associate Agent table, all four names together), not just the word "Full" which appears legitimately in "Full AI Infrastructure."

---

#### Nephew: `contract-enforcement-no-hardware.yml`

**What it blocks:** PRs containing hardware/infrastructure content

**Checks:**
```bash
# Check 1: AI machine specs
grep -r "MacBook Pro M5\|Mac mini M4\|DGX Spark\|Jetson Thor\|Node A\|Node B" --include="*.md" . | grep -v "REPOS-CONTRACT"
# Fails if found

# Check 2: Network hardware
grep -r "Flint 2\|Slate AX" --include="*.md" . | grep -v "REPOS-CONTRACT"
# Fails if found

# Check 3: WireGuard topology
grep -r "WireGuard.*Gateway\|WireGuard.*Topology\|Encrypted WireGuard Tunnel" --include="*.md" . | grep -v "REPOS-CONTRACT"
# Fails if found

# Check 4: Server deployment scripts
grep -r "nginx.*vhost\|fail2ban.*sshd\|iptables.*lockdown" --include="*.sh" --include="*.conf" . | grep -v "REPOS-CONTRACT"
# Fails if found

# Check 5: Runtime stack installation
grep -r "init-client-assistant\|bootstrap.sh.*redis" --include="*.sh" --include="*.md" . | grep -v "REPOS-CONTRACT"
# Fails if found
```

---

### 3. CI Workflow Triggers

```yaml
on:
  push:
    branches: [main]
    paths:
      - '**/*.md'
      - '**/*.swift'
      - '**/*.tsx'
      - '**/*.ts'
      - '**/*.sh'
      - '**/*.conf'
  pull_request:
    branches: [main]
    paths:
      - '**/*.md'
      - '**/*.swift'
      - '**/*.tsx'
      - '**/*.ts'
      - '**/*.sh'
      - '**/*.conf'
```

**Runs on:**
- Push to main branch
- Pull requests to main
- Only when relevant files change (`.md`, `.swift`, `.sh`, `.conf`, etc.)

---

## CI Failure Messages

### If You-Sir Juan PR fails:

```
❌ FAIL: Found Associate Agent definitions in You-Sir Juan
You-Sir Juan MUST NOT contain Associate Agent personas.
Move persona content to Nephew repo.
```

**Action:** Move persona/table content to `nephew/skills/` or `nephew/docs/meta-library/`

---

### If Nephew PR fails:

```
❌ FAIL: Found hardware specs in Nephew
Nephew MUST NOT contain hardware specs.
Move hardware specs to You-Sir Juan repo.
```

**Action:** Move hardware specs to `yousirjuan/hardware/` or `yousirjuan/README.md`

---

### If contract sync check fails:

```
❌ FAIL: Contract missing section: Clear Boundaries
```

**Action:** Update `REPOS-CONTRACT.md` to include missing section

---

## Updating the Contract (Version Bump Process)

### Step 1: Make the Change

Example: Adding a new category to Nephew

### Step 2: Update Version in REPOS-CONTRACT.md

```markdown
**Version:** 1.1.0  # Bump minor for new category

## Version History
| Version | Date | Changes |
|---|---|---|
| 1.0.0 | May 16, 2026 | Initial contract |
| 1.1.0 | YYYY-MM-DD | Added "frameworks" category to Nephew |
```

### Step 3: Update Contract Hash (if major change)

```markdown
**Contract Hash:** `YSJ-NEPHEW-CONTRACT-v1.1.0`
```

### Step 4: Update CI Workflow (if new check needed)

If the change requires a new CI check, add it to `.github/workflows/`

### Step 5: Commit with Conventional Commit

```bash
git add REPOS-CONTRACT.md .github/workflows/
git commit -m "chore(contract): bump to 1.1.0, add frameworks category to Nephew"
git push origin main
```

### Step 6: CI Validates

- ✅ `contract-sync-check.yml` validates new version
- ✅ Content enforcement checks pass
- ✅ PR can be merged

---

## Bypassing CI (Emergency Only)

**Do not bypass** unless you have explicit approval from Avery Goodman.

If you need an exception:

1. **Open a discussion issue** explaining why the exception is needed
2. **Get approval** from Avery Goodman (GitHub comment approval)
3. **Update contract version** before merging (document the exception)
4. **Add temporary CI ignore** (only if absolutely necessary):
   ```yaml
   # In workflow file
   if: github.event_name == 'pull_request' && contains(github.event.pull_request.labels.*.name, 'contract-exception')
   ```

---

## Testing CI Locally

Before pushing, run local tests:

### Test You-Sir Juan (no personas):
```bash
cd /Users/nivram/Developer/yousirjuan
if grep -r "Associate Agent" --include="*.md" . | grep -v REPOS-CONTRACT; then
  echo "FAIL: Found persona"
  exit 1
else
  echo "✅ PASS"
fi
```

### Test Nephew (no hardware):
```bash
cd /Users/nivram/Developer/nephew
if grep -r "MacBook Pro M5\|DGX Spark\|Flint 2" --include="*.md" . | grep -v REPOS-CONTRACT; then
  echo "FAIL: Found hardware"
  exit 1
else
  echo "✅ PASS"
fi
```

### Test contract version exists:
```bash
if grep -q 'Contract Version.*[0-9]\.[0-9]\.[0-9]' REPOS-CONTRACT.md; then
  echo "✅ PASS: Contract version present"
else
  echo "FAIL: Missing version"
  exit 1
fi
```

---

## Files Created

| File | Purpose |
|---|---|
| `yousirjuan/.github/workflows/contract-enforcement-no-persona.yml` | Blocks persona/interface content in You-Sir Juan [cite:57] |
| `yousirjuan/.github/workflows/contract-sync-check.yml` | Validates REPOS-CONTRACT.md exists and is complete [cite:45] |
| `nephew/.github/workflows/contract-enforcement-no-hardware.yml` | Blocks hardware content in Nephew [cite:44] |
| `nephew/.github/workflows/contract-sync-check.yml` | Validates REPOS-CONTRACT.md exists and is complete [cite:46] |
| `yousirjuan/REPOS-CONTRACT.md` | Full contract with version 1.0.0 [cite:50] |
| `nephew/REPOS-CONTRACT.md` | Quick-reference contract linking to full [cite:51] |
| `CI-CONTRACT-GUIDE.md` | This document - versioning & CI explanation |

---

## Summary

**Contract is versioned as:** `1.0.0` with hash `YSJ-NEPHEW-CONTRACT-v1.0.0` [cite:50][cite:51]

**CI enforces via:**
- 4 GitHub Actions workflows (2 per repo) [cite:43][cite:44][cite:45][cite:46]
- Content pattern matching (grep for forbidden content)
- Contract structural validation (required sections, version presence)
- Automatic PR blocking on failure

**Result:** Any PR violating repo boundaries fails CI automatically. No manual enforcement needed.
