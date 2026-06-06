# Free tier outputs — basic instance info only.
#
# Full Blueprint adds:
#   - hermes_gateway_url  (http://<ip>:8642)
#   - ssh_command         (ready-to-paste ssh string)
#   - elastic_ip          (static IP that survives restarts)
#   - bootstrap_status    (CloudWatch metric: did user_data finish?)

output "instance_id" {
  description = "EC2 instance ID — use with start.sh: export AI_INSTANCE_ID=..."
  value       = aws_instance.ai_gpu.id
}

output "public_ip" {
  description = "Current public IP — changes after every start/stop. Use Elastic IP (full Blueprint) for a stable address."
  value       = aws_instance.ai_gpu.public_ip
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.ai_sg.id
}

output "next_steps" {
  description = "What to do after terraform apply"
  value       = <<-EOT

    ── Quick start ───────────────────────────────────────────
    1. Export instance ID for scripts:
       export AI_INSTANCE_ID=${aws_instance.ai_gpu.id}

    2. Start the instance:
       ./scripts/start.sh

    3. SSH in and set up services manually:
       ssh -i ~/.ssh/hermes-ai-key ubuntu@${aws_instance.ai_gpu.public_ip}

    ── Skip manual setup ─────────────────────────────────────
    Get user_data.sh + pull-model.sh + stop.sh in the full Blueprint:
    https://payhip.com/b/nkpSv
    ──────────────────────────────────────────────────────────

  EOT
}
