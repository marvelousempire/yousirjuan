# 02 — Generate the fine-grained PAT

## Goal

Create a GitHub fine-grained personal access token scoped to `marvelousempire/*` with read-only access. Required because `sync-and-drift.sh` running as root on vps-godaddy has no SSH identity for GitHub — Option C from the parent ticket's decision matrix.

## Steps

1. **Open** [GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens](https://github.com/settings/personal-access-tokens/new).
2. **Token name:** `vps-godaddy-sync-and-drift` (descriptive; the name shows in audit logs).
3. **Expiration:** 366 days (the cap for fine-grained PATs). Set a calendar reminder for 350 days from today to rotate.
4. **Resource owner:** `marvelousempire`.
5. **Repository access:** **All repositories** under the resource owner.
6. **Permissions → Repository permissions:**
   - **Contents:** **Read-only**
   - **Metadata:** **Read-only** (mandatory; auto-included)
   - Everything else: **No access**
7. **Generate token** → copy it immediately. GitHub shows it once.
8. **Do NOT paste the token into chat, the PR description, or any committed file.** It goes only into the installer's stdin via the next runbook.

## Why these specific scopes

- The script only **reads** from GitHub (clones bare repos, fetches refs) and writes only to GitLab via SSH. Write scope on GitHub is unnecessary and dangerous if leaked.
- "All repositories" is acceptable because the operator owns the org and the script tracks 88+ repos. If this were a multi-tenant context, restrict to a curated list.

## Success criteria

- A token of the form `github_pat_11AAAAA...` exists in your clipboard.
- The token is recorded **only in your clipboard** — not in shell history, not in any committed file.

## Undo

Token isn't deployed yet, just generated. To revoke: GitHub → same Settings page → Revoke. (Once a token leaks, revoke immediately — there is no second chance.)

## Next

Runbook 03 — deploy this token to vps-godaddy via `install-credential.sh`.
