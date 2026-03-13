# Packer template for building AMI with monitoring agents
# Test: Datadog Agent and Fluent Bit Docker images

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "datadog_api_key" {
  type      = string
  sensitive = true
}

source "amazon-ebs" "monitoring" {
  ami_name      = "monitoring-agents-{{timestamp}}"
  instance_type = "t3.medium"
  region        = var.region
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
}

build {
  sources = ["source.amazon-ebs.monitoring"]

  # Install Docker
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y docker.io",
      "sudo systemctl enable docker",
      "sudo systemctl start docker"
    ]
  }

  # Test: Pull Datadog Agent from AWS ECR Public
  provisioner "shell" {
    inline = [
      "sudo docker pull public.ecr.aws/datadog/agent:7.50.0",
      "sudo docker tag public.ecr.aws/datadog/agent:7.50.0 datadog/agent:latest"
    ]
  }

  # Test: Pull Fluent Bit from Docker Hub
  provisioner "shell" {
    inline = [
      "sudo docker pull amazon/aws-for-fluent-bit:2.34.3",
      "sudo docker tag amazon/aws-for-fluent-bit:2.34.3 fluent-bit:latest"
    ]
  }

  # Test: Setup Datadog container configuration
  provisioner "file" {
    content = <<-EOF
      #!/bin/bash
      docker run -d --name datadog-agent \
        -e DD_API_KEY=${var.datadog_api_key} \
        -e DD_SITE="datadoghq.com" \
        -e DD_LOGS_ENABLED=true \
        -e DD_APM_ENABLED=true \
        -v /var/run/docker.sock:/var/run/docker.sock:ro \
        -v /proc/:/host/proc/:ro \
        -v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro \
        datadog/agent:7.50.0
    EOF
    destination = "/tmp/start-datadog.sh"
  }

  # Test: Setup Fluent Bit container configuration
  provisioner "file" {
    content = <<-EOF
      #!/bin/bash
      docker run -d --name fluent-bit \
        -v /var/log:/var/log:ro \
        amazon/aws-for-fluent-bit:2.34.3 \
        /fluent-bit/bin/fluent-bit -c /fluent-bit/etc/fluent-bit.conf
    EOF
    destination = "/tmp/start-fluent-bit.sh"
  }

  # Test: Additional registry variants in comments
  provisioner "shell" {
    inline = [
      "# Alternative registries for testing:",
      "# docker pull docker.io/datadog/agent:7.50.0",
      "# docker pull index.docker.io/datadog/agent:7.50.0", 
      "# docker pull docker.mirror.hashicorp.services/datadog/agent:7.50.0",
      "# docker pull docker.io/amazon/aws-for-fluent-bit:2.34.3",
      "echo 'Monitoring agents configured'"
    ]
  }

  post-processor "manifest" {
    output = "manifest.json"
  }
}
