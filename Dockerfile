# --- Builder stage: install tools & build artifacts ---
FROM node:20-bookworm-slim AS builder

# Install OS packages from Aptfile
# (If you need build tools like git, python3, build-essential, add them here too.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates bash curl git \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install only the OS packages you listed
# (This does a second apt run so we keep the base utilities above regardless.)
COPY Aptfile ./
RUN if [ -s Aptfile ]; then \
      apt-get update && xargs -a Aptfile apt-get install -y --no-install-recommends && \
      rm -rf /var/lib/apt/lists/* ; \
    fi

# Install npm deps (use ci for reproducibility)
COPY package*.json ./
RUN npm ci --no-audit --no-fund

# Copy the rest and run your build
COPY . .
# Make sure build.sh is executable
RUN bash ./scripts/build.sh && test -d cryptpad || echo 'Cryptpad folder not found'

# --- Runtime stage: smaller image with only what's needed to run ---
FROM node:20-bookworm-slim AS runtime

# Copy node_modules and built artifacts from the builder
COPY --from=builder --chmod=555 --chown=10001:10001 /app /app/

RUN install -d -m 0750 -o 10001 -g 10001 /app/cryptpad/data
RUN install -d -m 0750 -o 10001 -g 10001 /app/cryptpad/datastore
RUN install -d -m 0750 -o 10001 -g 10001 /app/cryptpad/blob
RUN install -d -m 0750 -o 10001 -g 10001 /app/cryptpad/block
RUN install -d -m 0750 -o 10001 -g 10001 /app/cryptpad/customize

VOLUME ["/app/cryptpad/data", "/app/cryptpad/datastore", "/app/cryptpad/blob", "/app/cryptpad/block", "/app/cryptpad/customize"]

# (Optional) create a non-root user
USER 10001:10001

# Environment
ENV NODE_ENV=production
ENV PORT=3000
ENV CRYPTPAD_HTTP_ADDRESS=0.0.0.0

WORKDIR /app/cryptpad
EXPOSE 3000 3003

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000', r => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"

CMD ["node", "server.js"]
