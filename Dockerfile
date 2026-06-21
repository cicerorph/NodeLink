# Stage 1: Builder
FROM oven/bun:1-alpine AS builder

# Build tools still needed — node-libsamplerate's postinstall compiles
# native code with cmake/make regardless of which package manager runs it
RUN apk add --no-cache git python3 make cmake g++

# Same CMake 4.x compatibility fix as before
ENV CMAKE_POLICY_VERSION_MINIMUM=3.5

WORKDIR /app

COPY package.json bun.lockb* ./

# --production skips devDependencies and skips the "prepare" lifecycle script
RUN bun install --production

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
