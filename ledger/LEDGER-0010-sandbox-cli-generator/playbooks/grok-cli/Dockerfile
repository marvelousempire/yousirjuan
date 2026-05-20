# Sandbox image for grok-cli (xAI's Grok CLI Beta).

FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl wget git jq python3 python3-pip \
      nodejs npm \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Grok CLI Beta is distributed via npm as @x-ai/grok-cli at the time of
# writing. If xAI ships a different channel (homebrew, standalone binary,
# etc.) update this line.
RUN npm install -g @x-ai/grok-cli || \
    echo "[sandbox-grok-cli] grok-cli install failed — update Dockerfile with the current install method"

RUN useradd -m -u 1000 -s /bin/bash sandbox && \
    mkdir -p /workspace && chown sandbox:sandbox /workspace

USER sandbox
WORKDIR /workspace

ENV PS1='[sandbox:grok-cli] \w \$ '

# Default to a help prompt rather than dropping into an empty shell.
CMD ["/bin/bash", "-c", "echo 'Grok CLI sandbox. Try: grok --help' && exec /bin/bash"]
