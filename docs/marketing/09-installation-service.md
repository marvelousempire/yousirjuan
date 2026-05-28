# Installation Service

**Tagline:** We come to your home. We set it up. We hand you the keys.

---

## What it is

You-Sir Juan™ is not a download-and-configure product. For Full and Standard tier customers, we provide a complete white-glove installation service — a technician comes to the household, installs and configures the entire stack, and leaves the family with a working system they understand.

---

## Why it matters

Private AI infrastructure is powerful. It is also complex. The gap between "the product exists" and "my family can use it comfortably" is the installation. We close that gap completely.

The goal: every family member is comfortable using their Associate Agent before the technician leaves. Not "here's how to configure it later." Working, on day one.

---

## What's included

### Pre-delivery
- GL.iNet router arrives pre-loaded with the household's WireGuard configuration
- All WireGuard keys generated, peer configs written, firewall rules set
- No configuration required on delivery — plug it in, it works

### On-site installation (half day)
1. **Network setup** — GL.iNet router installed as the household's private AI gateway; existing Mac mini or MacBook joined to the WireGuard mesh
2. **Runtime provisioning** — Ansible playbook runs on the Mac mini: Ollama, Postgres, Redis, Qdrant, Kokoro TTS, nginx all configured and started
3. **Kiosk placement** — iPad Pro (Full) or Pi touchscreen (Standard) mounted and configured; Guided Access enabled
4. **Member enrollment** — Each family member's face enrolled via the kiosk camera; Associate Agents named and voice-selected by each member
5. **Onboarding** — Each member completes their train-your-associate flow; the system is ready to use
6. **Handoff walkthrough** — Technician walks the household through basic use: how to talk to the Associate, how to train it, how to update preferences

### Post-installation
- 30-day support window — remote assistance for any issues
- Documentation left with the household
- Recovery procedures documented in case of hardware failure

---

## The tech stack behind the install

The Ansible playbook wraps the existing shell installers (`installers/linux.sh`, `installers/macos.sh`) and extends them for the full stack:
- Detects hardware (Mac mini M4, MacBook, or Pi-class ARM)
- Pulls and configures all Docker services from `docker-compose.yml`
- Seeds the member registry with household-specific face IDs and paradigms
- Configures nginx with the household's domain or local hostname
- Sets up automatic startup on boot

A technician with a standard laptop can complete the full install in under 60 minutes.

---

## Who it's for

Any household that wants a working system — not a project. The installation service is what makes You-Sir Juan™ a product you hand to a family, not a kit you hand to a developer.
