# Build upstream Paperclip from a pinned ref.
FROM node:22-bookworm AS paperclip-build
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*
RUN corepack enable

ARG PAPERCLIP_REPO=https://github.com/paperclipai/paperclip.git
ARG PAPERCLIP_REF=v2026.609.0

WORKDIR /paperclip
RUN git clone --depth 1 --branch "${PAPERCLIP_REF}" "${PAPERCLIP_REPO}" .

# Fork patch: enable creating openclaw_gateway agents directly from the "Add agent"
# UI (un-hide the tile + render a create form with URL + token). Applied to SOURCE
# before the build so it compiles into the UI bundle. Fail-closed: the build aborts
# if the patch does not apply cleanly (e.g. after a future PAPERCLIP_REF bump) —
# that hard error is the signal to re-generate the patch for the new ref.
COPY openclaw-gateway-create.patch /tmp/openclaw-gateway-create.patch
RUN git apply --check /tmp/openclaw-gateway-create.patch \
 && git apply /tmp/openclaw-gateway-create.patch \
 && echo "Applied openclaw-gateway-create.patch (UI tile create-flow)"

RUN pnpm install --frozen-lockfile
RUN pnpm --filter @paperclipai/ui build
RUN pnpm --filter @paperclipai/plugin-sdk build
RUN pnpm --filter @paperclipai/server build
RUN test -f server/dist/index.js

# Patch (upstream Issue #6344): @paperclipai/adapter-openclaw-gateway hardcodes
# PROTOCOL_VERSION=3, but OpenClaw 2026.5.18+ requires protocol 4. Bump it so
# Paperclip can connect to our OpenClaw 2026.5.20 gateway (and the Hermes WS
# adapter, which speaks the same gateway protocol). Safe here: we only run the
# newer OpenClaw, so dropping v3 backward-compat costs us nothing.
RUN set -e; \
    echo "Patching openclaw-gateway PROTOCOL_VERSION 3->4 (Issue #6344)..."; \
    F="$(grep -rl 'PROTOCOL_VERSION = 3' /paperclip 2>/dev/null || true)"; \
    if [ -z "$F" ]; then echo "ERROR: 'PROTOCOL_VERSION = 3' not found — adapter changed; re-check patch"; exit 1; fi; \
    echo "$F" | xargs sed -i 's/PROTOCOL_VERSION = 3/PROTOCOL_VERSION = 4/g'; \
    echo "Patched PROTOCOL_VERSION 3->4 in:"; echo "$F"

# Runtime image (direct Paperclip server, no wrapper).
FROM node:22-bookworm
ENV NODE_ENV=production
ENV CLAUDE_CODE_BUBBLEWRAP=1
# Match upstream production image defaults (paperclipai/paperclip Dockerfile) so
# agent tooling, OpenCode, and config paths behave the same in containers.
ENV HOME=/paperclip \
    PAPERCLIP_INSTANCE_ID=default \
    PAPERCLIP_CONFIG=/paperclip/instances/default/config.json \
    OPENCODE_ALLOW_ALL_MODELS=true

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    jq \
    openssh-client \
    ripgrep \
    && rm -rf /var/lib/apt/lists/*
RUN corepack enable

WORKDIR /app
COPY --from=paperclip-build /paperclip /app

WORKDIR /wrapper
COPY package.json /wrapper/package.json
RUN npm install --omit=dev && npm cache clean --force
COPY src /wrapper/src
COPY scripts/entrypoint.sh /wrapper/entrypoint.sh
COPY scripts/bootstrap-ceo.mjs /wrapper/template/bootstrap-ceo.mjs
RUN chmod +x /wrapper/entrypoint.sh

# Optional local adapters/tools parity with upstream Dockerfile.
RUN npm install --global --omit=dev @anthropic-ai/claude-code@latest @openai/codex@latest opencode-ai
RUN npm install --global --omit=dev tsx
RUN mkdir -p /paperclip \
    && chown -R node:node /app /paperclip /wrapper

# Railway sets PORT at runtime and this process binds to it.
# Entrypoint runs as root, fixes /paperclip volume permissions, then execs as node.
EXPOSE 3100
ENTRYPOINT ["/wrapper/entrypoint.sh"]
CMD ["node", "/wrapper/src/server.js"]
