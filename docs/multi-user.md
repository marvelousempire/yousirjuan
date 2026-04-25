# Multi-user — adding family + family office

Open WebUI is multi-user. Each user has their own chats, knowledge bases, custom prompts, settings — totally isolated from other users.

## Two ways to add users

### Method A — Admin invites (default, what we have today)

1. You sign in to Open WebUI as admin (`book@averyhandyman.com`).
2. **Admin Panel → Users → "Add User"**.
3. Enter their email + initial password. Send those over a secure channel (1Password share, signal message, etc.).
4. They sign in, change the password.

Pros: simple, no external dependencies.
Cons: you're managing passwords for everyone; you have to send them.

### Method B — Sign in with Google (OAuth) — recommended for family office

Each person clicks "Sign in with Google" → uses their own Google account → Open WebUI auto-creates their account if their email is on the whitelist.

Setup walkthrough: see [`oauth-google.md`](oauth-google.md).

Pros: no passwords to manage. Whitelist by email or by entire domain (`@yousirjuan.ai`). Familiar UX.
Cons: each user needs a Google account.

## User roles in Open WebUI

| Role | Can |
|---|---|
| **Admin** | Everything: invite users, change settings, delete chats, install Tools / Functions / Models that any user can use |
| **User** | Use chat, manage their own chats / prompts / knowledge / models |
| **Pending** | Just signed up, awaiting admin approval (off by default; turn on if signups become public) |

Change a user's role: **Admin Panel → Users → click their row → Role dropdown**.

## Sharing knowledge between users

By default, each user's uploaded documents are private to them. To **share**:

1. Admin (you) uploads a knowledge base via **Workspace → Knowledge → Create**.
2. Admin creates a custom Model (**Workspace → Models → Create**) that includes that knowledge.
3. Admin publishes the model: **Workspace → Models → click model → toggle "Public"**.
4. Now every user sees the model in their dropdown and can chat with it (the knowledge is read-only to them).

Use case: family office uploads "Q4 financials" + "Bylaws" as a shared "Family Office Assistant" model. Everyone in the family can ask it questions. Their individual chat histories with the model are still private.

## Disabling signup

Once admin is claimed, **always** disable signups:

```
Admin Panel → Settings → General → "Enable Signup" toggle OFF
```

Otherwise anyone who finds the URL can create an account.

If you set up Google OAuth, signup-via-OAuth is controlled separately — gate it via the email/domain whitelist (`OAUTH_ALLOWED_EMAILS` / `OAUTH_ALLOWED_DOMAINS`).

## Per-user data and isolation

Each user's data:
- **Chats** — `chat` table, scoped by `user_id`
- **Uploaded files** — `file` + `chat_file` tables; storage at `/app/backend/data/uploads/<user_id>/...`
- **Custom prompts** — `prompt` table, scoped by `user_id`
- **Custom models** — `model` table, scoped by `user_id`
- **Knowledge bases** — `knowledge` table; can be shared by admin

**The DB itself is one SQLite file** (`webui.db`). At the app layer, users cannot read each other's chats. At the system layer, root on the VPS can read everything. For real enterprise multi-tenant isolation (e.g. each family in a separate trust gets their own Open WebUI instance), run multiple containers with separate volumes.

## Practical onboarding playbook

For each family member:
1. Add them via Admin Panel → Users (or send them the OAuth-enabled URL once configured)
2. Send them a welcome message:
   > "Open https://hello.yousirjuan.ai. Click 'Sign in with Google' (or use the email/password I sent you). You can chat with our private AI. Your conversations are private to you. Some shared resources (like the Family Office Assistant) are available to everyone — they have a 🌐 icon in the model picker."
3. They explore. Done.

For each new device they want to use:
- It just works on the device's browser (since the VPS is publicly reachable at `hello.yousirjuan.ai`).
- For phone, they can also save the URL as a home-screen shortcut for an app-like icon.
