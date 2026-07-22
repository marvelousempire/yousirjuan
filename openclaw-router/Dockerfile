# OpenClaw Router — headless messaging-router mode.
#
# Strong isolation: no host filesystem mounts, drops all Linux capabilities,
# read-only rootfs (writes go to volume + tmpfs). Anything that needs to
# touch the host MUST go through the broker (see ../broker/) over SSH.
#
# What this container CAN do:
#   • Receive messages from OpenClaw channels (Telegram, Discord, Slack, etc.)
#   • Call Family Office models over canonical WireGuard addresses (or governed HTTPS)
#   • Reply to messages
#   • Run OpenClaw's built-in plugins that don't need host filesystem
#
# What it CANNOT do:
#   • Read your $HOME — no host mount
#   • Take screenshots — no display access
#   • Drive a browser on your Mac — no GUI access
#   • Use macOS voice / wake words — no audio access
#
# For ANY of those, it must call the broker (SSH-based, restricted vocabulary).

FROM node:24-bookworm-slim

LABEL org.opencontainers.image.title="yousirjuan-openclaw-router"
LABEL org.opencontainers.image.source="https://github.com/marvelousempire/yousirjuan"
LABEL org.opencontainers.image.licenses="proprietary"

# Install system deps
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        openssh-client \
        tini \
    && rm -rf /var/lib/apt/lists/*

# Non-root user inside container
RUN useradd -u 10001 -m -s /bin/bash claw

# Install OpenClaw under user prefix (no sudo, no system pollution)
USER claw
WORKDIR /home/claw
RUN mkdir -p /home/claw/.npm-global/bin
ENV NPM_CONFIG_PREFIX=/home/claw/.npm-global
ENV PATH=/home/claw/.npm-global/bin:$PATH
RUN npm install -g openclaw@latest

# typebox patch (works around upstream packaging bug — fetches typebox build files)
RUN cd /tmp \
    && npm init -y >/dev/null 2>&1 \
    && npm install --silent --no-save typebox@1.1.33 \
    && for d in /home/claw/.npm-global/lib/node_modules/openclaw/node_modules/typebox/build \
                /home/claw/.npm-global/lib/node_modules/openclaw/dist/extensions/google/node_modules/typebox/build; do \
        mkdir -p "$d" && cp -R /tmp/node_modules/typebox/build/. "$d/"; \
    done \
    && rm -rf /tmp/node_modules /tmp/package*.json

# OpenClaw config + state goes in a named volume
VOLUME /home/claw/.openclaw

# Gateway port
EXPOSE 18789

# tini handles PID 1 + signal forwarding
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["openclaw", "gateway", "--port", "18789"]
