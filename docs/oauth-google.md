# Sign in with Google (Open WebUI OAuth)

Replace email-and-password with **"Sign in with Google"**. Whitelist the family + family-office emails. No more password management; familiar UX for non-techies.

## Step 1 — create a Google OAuth client

1. Go to https://console.cloud.google.com/.
2. **Create a new project** (top-left dropdown → New Project) — name it `yousirjuan` or whatever. Wait ~10 sec for it to provision.
3. Make sure the new project is selected.
4. **APIs & Services → OAuth consent screen**:
   - User Type: **External**
   - App name: *You-Sir Juan*
   - User support email: your email
   - Developer contact: your email
   - Save & Continue through Scopes (none needed) and Test users (skip)
   - Back to Dashboard, click **PUBLISH APP** (otherwise it'll only allow test users).
5. **APIs & Services → Credentials → + CREATE CREDENTIALS → OAuth client ID**:
   - Application type: **Web application**
   - Name: *yousirjuan-openwebui*
   - **Authorized redirect URIs:** click ADD URI, paste:
     ```
     https://hello.yousirjuan.ai/oauth/google/callback
     ```
   - Create.
6. A modal pops up with **Client ID** and **Client Secret**. Copy both — you'll paste them into the VPS in Step 2.

## Step 2 — wire it into Open WebUI

SSH into the VPS:

```bash
ssh vps-godaddy
```

Set the env vars on the Open WebUI container:

```bash
docker stop open-webui
docker rm open-webui
docker run -d --name open-webui \
  -p 3000:8080 \
  --add-host=host.docker.internal:host-gateway \
  -v open-webui:/app/backend/data \
  -e USE_OLLAMA_DOCKER=false \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  -e WEBUI_SECRET_KEY="$(docker inspect open-webui --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | grep WEBUI_SECRET_KEY | cut -d= -f2)" \
  -e ENABLE_OAUTH_SIGNUP=true \
  -e GOOGLE_CLIENT_ID=PASTE_YOUR_CLIENT_ID_HERE.apps.googleusercontent.com \
  -e GOOGLE_CLIENT_SECRET=GOCSPX-PASTE_YOUR_SECRET_HERE \
  -e OAUTH_ALLOWED_DOMAINS=yousirjuan.ai \
  --restart always \
  ghcr.io/open-webui/open-webui:main
```

Wait ~30 sec for it to start, then refresh `https://hello.yousirjuan.ai`. You should see a **"Continue with Google"** button on the login page.

## Step 3 — control who can sign in

Use these env vars (set when running `docker run`):

| Env var | Effect |
|---|---|
| `OAUTH_ALLOWED_DOMAINS=yousirjuan.ai` | Anyone with `*@yousirjuan.ai` Google account can sign in |
| `OAUTH_ALLOWED_DOMAINS=yousirjuan.ai,nivram.ai` | Multiple domains allowed |
| `OAUTH_ALLOWED_EMAILS=alice@gmail.com,bob@gmail.com` | Specific emails only (more granular) |
| `OAUTH_MERGE_ACCOUNTS_BY_EMAIL=true` | If a user already has an Open WebUI account with the same email, link Google to it instead of duplicating |
| `ENABLE_OAUTH_SIGNUP=true` | Auto-create accounts for new whitelisted users on first OAuth login |
| `OAUTH_UPDATE_PICTURE_ON_LOGIN=true` | Use their Google profile photo as their Open WebUI avatar |

## Step 4 — disable password signup

After Google OAuth is working:

**Admin Panel → Settings → General → "Enable Signup" → OFF**.

This kills the email/password signup form. Login still works for accounts created via OAuth or admin invite. The "Continue with Google" button remains.

## Onboarding a family member

Send them this message:

> Hi! Open https://hello.yousirjuan.ai and click **"Continue with Google"**. Use your Google account (`you@yousirjuan.ai` or whatever's whitelisted). You'll land in our private AI — your conversations are yours alone. Models like *Family Office Assistant* are shared with the whole family. Reply if anything's confusing.

That's it. They click, they're in. No password, no email verification, no admin step required for whitelisted domains.

## Troubleshooting

| Symptom | Fix |
|---|---|
| "Continue with Google" button doesn't appear | `docker logs open-webui` — confirm `GOOGLE_CLIENT_ID` is set; restart container |
| Click "Continue with Google" → Google says "redirect_uri_mismatch" | The URI in your Google Cloud Console doesn't match the one Open WebUI is sending. Double-check it's exactly `https://hello.yousirjuan.ai/oauth/google/callback` |
| Signs in fine but says "User not allowed" | Email not on the whitelist. Add to `OAUTH_ALLOWED_DOMAINS` or `OAUTH_ALLOWED_EMAILS` and restart container. |
| Want to require admin approval before users can chat | Set `ENABLE_OAUTH_SIGNUP=false` AND `WEBUI_AUTH_TRUSTED_EMAIL_HEADER` is unset; users sign in but get "pending" role. You then promote them in Admin Panel. |
