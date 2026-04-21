# =============================================================================
# ACID Dockerfile - Multi-stage Production Build
# =============================================================================
# Build: docker build -t acid-api:latest .
# Run: docker run -p 8080:8080 acid-api:latest
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Build
# -----------------------------------------------------------------------------
FROM golang:1.24-alpine AS builder

# Build arguments for versioning
ARG VERSION=dev
ARG COMMIT=unknown
ARG DATE=unknown

# Install build dependencies
RUN apk add --no-cache \
    git \
    ca-certificates \
    tzdata \
    gcc \
    musl-dev

WORKDIR /build

# Copy go mod files first for caching
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the binary
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-s -w \
              -X main.version=${VERSION} \
              -X main.commit=${COMMIT} \
              -X main.date=${DATE}" \
    -o /build/acid-api \
    ./cmd/api

# -----------------------------------------------------------------------------
# Stage 2: Distroless Runtime
# -----------------------------------------------------------------------------
FROM gcr.io/distroless/static-debian12:nonroot AS runtime

# Copy CA certificates and timezone data
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# Copy the binary
COPY --from=builder /build/acid-api /acid-api

# Copy web assets
COPY --from=builder /build/web /web

# Use non-root user (distroless default is nonroot:65532)
USER nonroot:nonroot

# Expose port
EXPOSE 8080

# Health check - use native Go binary health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD ["/bin/sh", "-c", "nc -z localhost 8080 || exit 1"]

# Set entrypoint
ENTRYPOINT ["/acid-api"]

# Default arguments
CMD ["--port", "8080"]

# -----------------------------------------------------------------------------
# Stage 3: Development (optional)
# -----------------------------------------------------------------------------
FROM golang:1.24-alpine AS development

RUN apk add --no-cache git gcc musl-dev

WORKDIR /app

# Install air for hot reload (pinned version for Go 1.24 compatibility)
RUN go install github.com/air-verse/air@v1.52.3

COPY go.mod go.sum ./
RUN go mod download

COPY . .

EXPOSE 8080

CMD ["air", "-c", ".air.toml"]
