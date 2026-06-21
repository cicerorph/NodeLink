# Stage 1: Builder
FROM oven/bun:1-alpine AS builder

RUN apk add --no-cache git python3 make cmake g++

ENV CMAKE_POLICY_VERSION_MINIMUM=3.5

WORKDIR /app

COPY package.json bun.lockb* ./

# Strip the "prepare" script (husky git-hook setup) — devDependency we're
# not installing, and irrelevant in a container with no .git directory anyway
RUN sed -i '/"prepare":/d' package.json \
    && bun install --production

# Stage 2: Runner
FROM oven/bun:1-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY src/ ./src/
COPY config.default.js ./config.default.js
COPY package.json ./package.json
EXPOSE 3000
ENV NODELINK_SERVER_PORT=3000 \
    NODELINK_SERVER_HOST=0.0.0.0 \
    NODELINK_CLUSTER_ENABLED=true
CMD ["bun", "src/index.ts"]
