# Packer template for building Docker images with monitoring
# Test: Using Datadog and Fluent Bit as base images

packer {
  required_plugins {
    docker = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/docker"
    }
  }
}

# Test: Build from Datadog Agent base image
source "docker" "datadog-custom" {
  image  = "public.ecr.aws/datadog/agent:7.77.2"
  commit = true
  changes = [
    "LABEL version=1.0.0",
    "LABEL description='Custom Datadog Agent'"
  ]
}

# Test: Build from Fluent Bit base image
source "docker" "fluent-bit-custom" {
  image  = "amazon/aws-for-fluent-bit:2.31.12"
  commit = true
  changes = [
    "LABEL version=1.0.0",
    "LABEL description='Custom Fluent Bit'"
  ]
}

# Test: Multiple registry variants
source "docker" "datadog-dockerhub" {
  image  = "docker.io/datadog/agent:7.77.2"
  commit = true
}

source "docker" "datadog-hashicorp-mirror" {
  image  = "docker.mirror.hashicorp.services/datadog/agent:7.77.2"
  commit = true
}

build {
  name = "monitoring-images"
  
  sources = [
    "source.docker.datadog-custom",
    "source.docker.fluent-bit-custom"
  ]

  provisioner "shell" {
    inline = [
      "echo 'Base image: public.ecr.aws/datadog/agent:7.77.2'",
      "echo 'Base image: amazon/aws-for-fluent-bit:2.31.12'",
      "echo 'Customizing monitoring agent...'"
    ]
  }

  post-processor "docker-tag" {
    repository = "my-registry/datadog-agent"
    tags       = ["7.50.0", "latest"]
  }
}
