# Stage 1: Builder - Install dependencies
FROM node:25-alpine AS builder

# Build tools required for native modules (node-libsamplerate, etc.)
RUN apk add --no-cache git python3 make cmake g++

# CMake 4.x dropped support for old cmake_minimum_required() declarations;
# this lets older native deps configure without erroring out.
ENV CMAKE_POLICY_VERSION_MINIMUM=3.5

WORKDIR /app

# Copy lockfile too so npm installs exact, reproducible versions
COPY package.json package-lock.json* ./

RUN npm install --omit=dev

# Stage 2: Runner - Copy application code and run
FROM node:25-alpine

# Set working directory
WORKDIR /app

# Copy production dependencies from the builder stage
COPY --from=builder /app/node_modules ./node_modules

# Copy the rest of the application source code
# This includes the 'src' directory, default config, and package files for runtime information.
COPY src/ ./src/
COPY config.default.js ./config.default.js
COPY package.json ./package.json

# Expose the port the application listens on (default is 3000 from config.default.js)
EXPOSE 3000

# Set environment variables for configuration
# These can be overridden via docker-compose.yml or 'docker run -e'
# Example: NODELINK_SERVER_PASSWORD=your_secure_password
ENV NODELINK_SERVER_PORT=3000 \
    NODELINK_SERVER_HOST=0.0.0.0 \
    NODELINK_CLUSTER_ENABLED=true

# Command to run the application
# It uses the 'start' script defined in package.json
CMD ["npm", "start"]
