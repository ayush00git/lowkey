# Build stage
FROM golang:1.25-alpine AS builder

WORKDIR /app

# Copy module files first for better caching
COPY go.mod go.sum ./
RUN go mod download

# Copy source
COPY proto/ proto/
COPY server/ server/

# Build the signaling server
RUN CGO_ENABLED=0 GOOS=linux go build -o /signaling-server ./server/

# Runtime stage
FROM alpine:3.21

RUN apk add --no-cache ca-certificates

COPY --from=builder /signaling-server /signaling-server

ENV REDIS_ADDR=redis:6379
ENV GRPC_PORT=50051

EXPOSE 50051

CMD ["/signaling-server"]
