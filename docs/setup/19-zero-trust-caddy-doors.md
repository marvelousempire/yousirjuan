# 19. Zero-Trust Caddy Doors Architecture

## Overview

This document defines the new security model for You-Sir Juan: **WireGuard as transport only**, with Caddy providing mTLS authentication and routing for all services.

## Core Principles
- Default deny
- Per-device client certificates (short-lived)
- Service isolation via Docker networks (`control-net`, `voice-net`, `data-net`)
- Clean `.home` domains

## Caddy Deployment

See `docker/caddy/docker-compose.yml` (to be created).

## Device Certificate Installation
- MacBook M5 Max, iPhone 17 series, iPad Pro 13"
- One-time AirDrop + Settings install

## Next Steps
1. Deploy Caddy
2. Migrate services
3. Roll out certs to new iPhones + iPad

**Status**: Planning / In Progress