# Build stage
FROM node:22-alpine AS builder

WORKDIR /app

# Copy package files
COPY package.json package-lock.json* pnpm-lock.yaml* yarn.lock* ./

RUN corepack enable pnpm 2>/dev/null || true && \
    if [ -f pnpm-lock.yaml ]; then pnpm install --frozen-lockfile --ignore-scripts; \
    elif [ -f yarn.lock ]; then yarn install --frozen-lockfile --ignore-scripts; \
    else npm ci --ignore-scripts || npm install --ignore-scripts; fi

COPY . .

ENV NEXT_TELEMETRY_DISABLED=1
RUN npx fumadocs-mdx && npm run build

# Production stage
FROM node:22-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Create non-root user for Dokploy
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy built app
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 5973
ENV PORT=5973
ENV HOSTNAME="0.0.0.0"

CMD ["node", "server.js"]
