---
description: When building any app — native iOS + user web + marketing site + admin dashboard + backend / API all exist from day one. Never single-surface bootstraps that need painful retrofits later.
alwaysApply: true
---

# Parallel Surfaces From Day One

**Rule:** Every app, web app, or website starts with all surfaces in parallel — never a single-surface bootstrap with the expectation that the rest will be "retrofitted later." Retrofitting is where products go to die.

The five surfaces:

1. **Native iOS** (Swift / SwiftUI) — the user's primary device experience for any product that has meaningful daily use. Even if "we'll build the iOS app later" is the plan, scaffold the Xcode project on day one. Empty target with auth + a single tab is enough.
2. **User web** (`me.<domain>` / `app.<domain>`) — the signed-in user experience on a desktop browser. Sister surface to iOS; same auth, same data, same canonical URLs for shared profiles.
3. **Marketing web** (`<domain>` root) — the public-facing site. Hero, pricing, blog, public profile pages that the user web also serves (often via Next.js routing the same `/p/<id>` pages, or via a redirect tier).
4. **Admin dashboard** (`admin.<domain>`) — operator tools. Feature ledger, plan ledger, content moderation, billing, manual user override, support search. Started small but real — never a `localhost:port/admin` afterthought.
5. **Backend / API** (`api.<domain>`) — the durable source of truth. Postgres + a thin JSON-over-HTTPS API surface. All four front-end surfaces above talk to it. No frontend has its own database; no two frontends share a database directly.

## Why parallel from day one

**The retrofit tax compounds.** Every surface that gets added later forces:
- Schema migrations to make the existing data multi-tenant-or-multi-surface-aware
- Auth path retrofits (the iOS-only OAuth flow has to be redone for web; the web cookie session has to be redone for iOS)
- API renames (endpoints designed for one client get awkward when a second client needs different shapes)
- Marketing-site URL ↔ user-app URL collisions ("public profile" on the marketing site at `/p/<id>` conflicts with the signed-in user view at `/p/<id>` — solved cleanly when both exist day one)
- Admin tooling debt: every operational task that should be a one-click admin button becomes a manual SQL query because the dashboard doesn't exist yet

Each of those costs is far larger than the cost of scaffolding the surface empty on day one.

## What "parallel from day one" looks like concretely

For a brand-new project:

```
my-app/
├── apps/
│   ├── ios/                      # Xcode project, empty Swift target with auth shell
│   ├── user-web/                 # Next.js, /p/<id>/ public profile + signed-in surfaces
│   ├── marketing/                # Next.js, root domain marketing site
│   └── admin/                    # Next.js, admin.<domain> operator dashboard
├── backend/                      # Express + Postgres + migrations + JWT auth
├── docs/
│   ├── Plan-Master-Roadmap.md
│   └── Plan-<Feature>.md
└── scripts/                      # deploy + lifecycle scripts shared by all
```

Each `apps/<surface>/` has its own `package.json` and version, deployed independently. They share:
- The same auth provider on the backend
- The same Postgres schema
- The same TypeScript types (often via a shared `lib/` symlink or a published package)

## Day-one auth-surface scaffolding

Every surface starts with these in place even if everything else is empty:

| Surface | Day-one minimum |
|---|---|
| iOS | Sign in with Apple → JWT back → render "Hello, $displayName" on a single tab |
| User web | Same Sign in with Apple OAuth → cookie session → render "Hello, $displayName" |
| Marketing | Public landing page + a "Sign in" link that hands off to user web's auth |
| Admin | Separate operator auth (admin allowlist or SSO) → empty `/dashboard` with one stat row |
| Backend | `POST /auth/apple/callback`, `GET /auth/me`, `players` table, JWT signing |

A working sign-in flow on day one is the single best forcing function — it proves the multi-surface architecture works end-to-end before any feature ships.

## Anti-patterns this rule rejects

- **"We'll add the iOS app later"** — scaffold it empty on day one. An empty Xcode target costs nothing; a future "we need iOS now" panic costs months.
- **"Admin is just a hidden /admin route on the user app"** — the privilege model and the deploy cadence are different. Split the surface.
- **"The marketing site is hand-coded HTML at the root and the app lives on a subdomain"** — fine to start with a placeholder, but the marketing site should still be in the monorepo, deploying via the same pipeline, sharing the same design tokens.
- **"The backend is in the same monolith as the user web"** — for a personal local tool this is fine (see [`app-launch-workflow`](app-launch-workflow.md)). For anything that will have multiple clients, split it day one.
- **"Two frontends share a database directly"** — never. The backend is the only thing that talks to Postgres. Frontends call the API.

## When this rule does not apply

This rule applies to **product apps** — anything meant to be used by real users on real devices, even at v0.1. It does **not** apply to:

- Personal local tools — one user, one Mac, one purpose (see [`app-launch-workflow`](app-launch-workflow.md) for the simpler single-surface pattern).
- Throwaway prototypes meant to live for one demo and die.
- Library code, CLI utilities, scripts.

If you are not sure whether a thing is a "product app" or a "personal tool," ask. The difference is whether you expect a second human to ever use it.

## How to retrofit when you've already violated this rule

If the project is already past day one and one of the five surfaces is missing:

1. **Scope honestly.** "Adding marketing later" is not a one-week task on a project that's six months in. Schedule it.
2. **Plan the URL handoffs.** Marketing → user web sign-in, marketing public profile → user web's authenticated view of the same profile, user web → admin (operator-only, never user-facing link).
3. **Plan the auth handoffs.** A user signed into the user web should not have to sign in again to land on the marketing site's authenticated areas (e.g. their public profile editor). Same domain or shared session cookie scope.
4. **Add the empty version of the missing surface first.** Get it deployed at the right subdomain, on the right pipeline, with auth working. Then iterate. Do not try to ship the missing surface as a fully-featured launch — that's how scope creep kills the retrofit.

## See also

- [`app-launch-workflow`](app-launch-workflow.md) — single-surface personal-tool pattern (the opposite case)
- [`go-live-path`](go-live-path.md) — every shipped feature ends with migrate / deploy / smoke-test
- [`dev-discipline`](dev-discipline.md) — session opener / closer rituals that keep multi-surface parallel work honest
