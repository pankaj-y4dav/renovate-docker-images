# Generic HCL configuration for monitoring services
# Test: Datadog Agent and Fluent Bit image references

monitoring {
  enabled = true
  
  datadog {
    enabled = true
    # Test: AWS ECR Public registry
    image   = "public.ecr.aws/datadog/agent:7.50.0"
    api_key = env("DD_API_KEY")
    
    config {
      logs_enabled = true
      apm_enabled  = true
      site         = "datadoghq.com"
    }
    
    resources {
      cpu_limit    = "500m"
      memory_limit = "512Mi"
    }
  }
  
  fluent_bit {
    enabled = true
    # Test: Docker Hub registry
    image   = "amazon/aws-for-fluent-bit:2.31.12"
    
    config {
      log_level = "info"
      parsers   = ["docker", "json"]
    }
    
    resources {
      cpu_limit    = "200m"
      memory_limit = "256Mi"
    }
  }
}

# Test: Alternative registry configurations
monitoring_alternatives {
  datadog_dockerhub = "docker.io/datadog/agent:7.50.0"
  datadog_fqdn      = "index.docker.io/datadog/agent:7.50.0"
  datadog_mirror    = "docker.mirror.hashicorp.services/datadog/agent:7.50.0"
  
  fluent_bit_dockerhub = "docker.io/amazon/aws-for-fluent-bit:2.31.12"
  fluent_bit_mirror    = "docker.mirror.hashicorp.services/amazon/aws-for-fluent-bit:2.31.12"
}

# Test: Service definitions using image references
service "datadog" {
  type  = "container"
  image = "public.ecr.aws/datadog/agent:7.50.0"
  
  environment = {
    DD_API_KEY      = var.datadog_api_key
    DD_SITE         = "datadoghq.com"
    DD_LOGS_ENABLED = "true"
  }
  
  ports = [8125, 8126]
}

service "fluent-bit" {
  type  = "container"
  image = "amazon/aws-for-fluent-bit:2.31.12"
  
  volumes = [
    "/var/log:/var/log:ro",
    "/var/lib/docker/containers:/var/lib/docker/containers:ro"
  ]
  
  ports = [2020]
}

# Test: Deployment configuration
deployment "monitoring-stack" {
  containers = {
    datadog = {
      image = "public.ecr.aws/datadog/agent:7.50.0"
      tag   = "7.50.0"
    }
    fluent_bit = {
      image = "amazon/aws-for-fluent-bit:2.31.12"
      tag   = "2.31.12"
    }
  }
}
