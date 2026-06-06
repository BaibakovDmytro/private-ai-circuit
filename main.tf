provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

module "ai_instance" {
  source = "./modules/ai-instance"

  client_name       = var.client_name
  my_ip             = var.my_ip
  instance_type     = var.instance_type
  volume_size_gb    = var.volume_size_gb
  region            = var.region
  auto_stop_enabled = var.auto_stop_enabled
  low_cpu_threshold = var.low_cpu_threshold
  idle_minutes      = var.idle_minutes
}

# ── Outputs ───────────────────────────────────────────────────────────────────
# Full outputs.tf (instance_id, public_ip, ssh_command, hermes_url)
# is included in the full Blueprint package.
# See: https://payhip.com/b/nkpSv

output "next_steps" {
  value = <<-EOT

    ✓ Instance provisioned.

    To get your public IP and SSH command:
      aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=${var.client_name}-private-ai-gpu" \
        --query "Reservations[0].Instances[0].PublicIpAddress" \
        --output text

    Note: user_data.sh (auto-installs Ollama, NVIDIA drivers, Hermes) 
    is not included in the free tier. Manual setup required.
    Full Blueprint: https://payhip.com/b/nkpSv

  EOT
}
