#!/bin/bash

set -euo pipefail

# Deploy Datadog Agent and Fluent Bit monitoring stack
# This script demonstrates image references in shell scripts

DATADOG_IMAGE="public.ecr.aws/datadog/agent:7.77.0"
FLUENT_BIT_IMAGE="public.ecr.aws/aws-observability/aws-for-fluent-bit:2.31.12"

# Configuration
CLUSTER_NAME="${CLUSTER_NAME:-production}"
AWS_REGION="${AWS_REGION:-us-east-1}"
DD_API_KEY="${DD_API_KEY:-}"

if [ -z "$DD_API_KEY" ]; then
    echo "Error: DD_API_KEY environment variable is required"
    exit 1
fi

echo "Deploying monitoring stack..."
echo "  Datadog Agent: $DATADOG_IMAGE"
echo "  Fluent Bit: $FLUENT_BIT_IMAGE"
echo "  Cluster: $CLUSTER_NAME"
echo "  Region: $AWS_REGION"

# Pull images
echo "Pulling Docker images..."
docker pull "$DATADOG_IMAGE"
docker pull "$FLUENT_BIT_IMAGE"

# Deploy Datadog Agent
echo "Deploying Datadog Agent..."
docker run -d \
    --name datadog-agent \
    --restart unless-stopped \
    -e DD_API_KEY="$DD_API_KEY" \
    -e DD_SITE="datadoghq.com" \
    -e DD_LOGS_ENABLED=true \
    -e DD_APM_ENABLED=true \
    -e DD_PROCESS_AGENT_ENABLED=true \
    -e DD_TAGS="cluster:$CLUSTER_NAME,region:$AWS_REGION" \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    -v /proc/:/host/proc/:ro \
    -v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro \
    -p 8126:8126 \
    -p 8125:8125/udp \
    "$DATADOG_IMAGE"

# Deploy Fluent Bit
echo "Deploying Fluent Bit..."
docker run -d \
    --name fluent-bit \
    --restart unless-stopped \
    -e AWS_REGION="$AWS_REGION" \
    -e CLUSTER_NAME="$CLUSTER_NAME" \
    -v /var/log:/var/log:ro \
    -v /var/lib/docker/containers:/var/lib/docker/containers:ro \
    -p 2020:2020 \
    "$FLUENT_BIT_IMAGE"

echo "Monitoring stack deployed successfully!"
echo ""
echo "Access points:"
echo "  Datadog APM: http://localhost:8126"
echo "  Fluent Bit Metrics: http://localhost:2020"
