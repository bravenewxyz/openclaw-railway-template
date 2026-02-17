# Build openclaw from source to avoid npm packaging gaps (some dist files are not shipped).
FROM node:22-bookworm AS openclaw-build

# Dependencies needed for openclaw build
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    git \
    ca-certificates \
    curl \
    python3 \
    make \
    g++ \
  && rm -rf /var/lib/apt/lists/*

# Install Bun (openclaw build uses it)
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /openclaw

# OpenClaw version control:
# - Set OPENCLAW_VERSION Railway variable to use a specific tag (e.g., v2026.2.15)
# - If not set, defaults to main branch (original behavior)
# - Can also override locally with --build-arg OPENCLAW_VERSION=<tag>
ARG OPENCLAW_VERSION
RUN set -eu; \
  if [ -n "${OPENCLAW_VERSION:-}" ]; then \
    REF="${OPENCLAW_VERSION}"; \
    echo "✓ Using OpenClaw ${REF}"; \
  else \
    REF="main"; \
    echo "⚠ OPENCLAW_VERSION not set, using main branch (may be unstable)"; \
  fi; \
  git clone --depth 1 --branch "${REF}" https://github.com/openclaw/openclaw.git .

# Patch: relax version requirements for packages that may reference unpublished versions.
# Apply to all extension package.json files to handle workspace protocol (workspace:*).
RUN set -eux; \
  find ./extensions -name 'package.json' -type f | while read -r f; do \
    sed -i -E 's/"openclaw"[[:space:]]*:[[:space:]]*">=[^"]+"/"openclaw": "*"/g' "$f"; \
    sed -i -E 's/"openclaw"[[:space:]]*:[[:space:]]*"workspace:[^"]+"/"openclaw": "*"/g' "$f"; \
  done

RUN pnpm install --no-frozen-lockfile
RUN pnpm build
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:install && pnpm ui:build


# Runtime image
FROM node:22-bookworm
ENV NODE_ENV=production

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    build-essential \
    gcc \
    g++ \
    make \
    procps \
    file \
    git \
    python3 \
    pkg-config \
    sudo \
    jq \
    rsync \
    zip \
    ffmpeg \
  && rm -rf /var/lib/apt/lists/*

# Install bun (global)
RUN curl -fsSL https://bun.sh/install | BUN_INSTALL=/usr/local bash

# Install MEGAcmd (needs libfuse2 + fuse)
RUN apt-get update \
  && apt-get install -y --no-install-recommends libfuse2 fuse \
  && curl -fsSL https://mega.nz/linux/repo/Debian_12/amd64/megacmd-Debian_12_amd64.deb -o /tmp/megacmd.deb \
  && dpkg -i /tmp/megacmd.deb \
  && rm /tmp/megacmd.deb \
  && rm -rf /var/lib/apt/lists/*

# Install Railway CLI
RUN npm install -g @railway/cli

# Install trash-cli (safer than rm)
RUN npm install -g trash-cli

# Install Homebrew (must run as non-root user)
# Create a user for Homebrew installation, install it, then make it accessible to all users
RUN useradd -m -s /bin/bash linuxbrew \
  && echo 'linuxbrew ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER linuxbrew
RUN NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

USER root
RUN chown -R root:root /home/linuxbrew/.linuxbrew
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"

WORKDIR /app

# Wrapper deps
RUN corepack enable
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --prod --frozen-lockfile && pnpm store prune

# Copy built openclaw
COPY --from=openclaw-build /openclaw /openclaw

# Provide a openclaw executable
RUN printf '%s\n' '#!/usr/bin/env bash' 'exec node /openclaw/dist/entry.js "$@"' > /usr/local/bin/openclaw \
  && chmod +x /usr/local/bin/openclaw

COPY src ./src

ENV PORT=8080
ENV HOME=/data

# Pre-seed github.com SSH host key so git works without StrictHostKeyChecking=no
RUN mkdir -p /root/.ssh && ssh-keyscan -t ed25519 github.com >> /root/.ssh/known_hosts 2>/dev/null

EXPOSE 8080

# On startup: init permissions on persistent home, then start
CMD ["bash", "-c", "[ -x /data/workspace/scripts/init-home.sh ] && bash /data/workspace/scripts/init-home.sh; exec node src/server.js"]
