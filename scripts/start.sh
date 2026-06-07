#!/bin/bash
# Private AI Circuit — Start instance (free tier)
# Full version with SSH health check, service status, model list: payhip.com/b/nkpSv

set -euo pipefail

INSTANCE_ID="${AI_INSTANCE_ID:-}"
AWS_REGION="${AWS_REGION:-eu-central-1}"

if [ -z "$INSTANCE_ID" ]; then
  echo "Set your instance ID: export AI_INSTANCE_ID=i-0abc123..."
  exit 1
fi

# Check current state before sending start signal
# Without this: if instance is already running, aws ec2 start-instances
# returns an error and the script exits on set -e
STATE=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --region "$AWS_REGION" \
  --query "Reservations[0].Instances[0].State.Name" \
  --output text 2>/dev/null || echo "unknown")

if [ "$STATE" = "terminated" ]; then
  echo "✗ Instance is terminated — recreate it with terraform apply."
  exit 1
fi

if [ "$STATE" != "running" ]; then
  echo "Starting $INSTANCE_ID in $AWS_REGION..."
  aws ec2 start-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$AWS_REGION" \
    --output text > /dev/null

  echo "Waiting for running state..."
  aws ec2 wait instance-running \
    --instance-ids "$INSTANCE_ID" \
    --region "$AWS_REGION"
else
  echo "Instance already running."
fi

IP=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --region "$AWS_REGION" \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

if [ -z "$IP" ] || [ "$IP" = "None" ]; then
  echo "✗ Could not get public IP. Add Elastic IP or check networking."
  exit 1
fi

echo ""
echo "✓ Instance running"
echo "  IP        : $IP"
echo "  SSH       : ssh -i ~/.ssh/hermes-ai-key ubuntu@$IP"
echo "  Hermes    : http://$IP:8642"
echo ""
echo "Note: if this is a fresh instance, install services manually."
echo "Full Blueprint with auto-setup: https://payhip.com/b/nkpSv"
