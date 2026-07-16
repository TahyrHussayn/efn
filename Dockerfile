# syntax=docker.io/docker/dockerfile:1

# ──────────────────────────────────────────────
# Stage 1 — Base: shared Alpine + libc6-compat
# ──────────────────────────────────────────────
FROM node:22-alpine AS base
RUN apk add --no-cache libc6-compat
WORKDIR /app

# ──────────────────────────────────────────────
# Stage 2 — Dependencies: install with pnpm
# ──────────────────────────────────────────────
FROM base AS deps

# Install pnpm directly (corepack is being removed from Node 25+)
RUN npm install -g pnpm@11

# Copy only the files pnpm needs to resolve + install
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./

# Install dependencies — frozen lockfile ensures reproducible builds
# Cache mount speeds up rebuilds by persisting the pnpm store across builds
RUN --mount=type=cache,target=/root/.local/share/pnpm/store \
    pnpm install --frozen-lockfile

# ──────────────────────────────────────────────
# Stage 3 — Builder: build the Next.js app
# ──────────────────────────────────────────────
FROM base AS builder

# Reuse pnpm from deps stage instead of re-installing
COPY --from=deps /usr/local/lib/node_modules/pnpm /usr/local/lib/node_modules/pnpm
RUN ln -s /usr/local/lib/node_modules/pnpm/bin/pnpm.cjs /usr/local/bin/pnpm

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Disable Next.js telemetry during build
ENV NEXT_TELEMETRY_DISABLED=1

RUN --mount=type=cache,target=/app/.next/cache \
    pnpm run build

# ──────────────────────────────────────────────
# Stage 4 — Runner: minimal production image
# ──────────────────────────────────────────────
FROM base AS runner

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

LABEL org.opencontainers.image.source="https://github.com/TahyrHussayn/efn"
LABEL org.opencontainers.image.description="EFN — Next.js standalone production image"
LABEL org.opencontainers.image.licenses="UNLICENSED"

# Create a non-root user for security
RUN addgroup --system --gid 1001 nodejs && \
    adduser  --system --uid 1001 nextjs

# Copy public assets
COPY --from=builder /app/public ./public

# Copy the standalone server + its minimal node_modules
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./

# Copy pre-built static assets (.next/static is NOT included in standalone)
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://127.0.0.1:3000/ || exit 1

# standalone output produces a self-contained server.js
CMD ["node", "server.js"]
