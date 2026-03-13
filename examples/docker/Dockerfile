# Multi-stage build example with Datadog Agent
FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .

# Runtime stage with Datadog
FROM public.ecr.aws/datadog/agent:7.76.3

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy application from builder
COPY --from=builder /app /app

# Configure Datadog
ENV DD_LOGS_ENABLED=true \
    DD_APM_ENABLED=true \
    DD_DOGSTATSD_NON_LOCAL_TRAFFIC=true

WORKDIR /app

EXPOSE 8126 8125

CMD ["agent", "start"]
