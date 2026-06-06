#!/bin/bash
# Private AI Circuit — Start instance
# Full version (with SSH health check, service status, model list): in paid Blueprint

set -euo pipefail

INSTANCE_ID="${AI_INSTANCE_ID:-}"
AWS_REGION="${AWS_REGION:-eu-central-1}"

if [ -z "$INSTANCE_ID" ]; then
  echo "Set your instance ID: export AI_INSTANCE_ID=i-0abc123..."
  exit 1
fi

echo "Starting $INSTANCE_ID in $AWS_REGION..."
aws ec2 start-instances --instance-ids "$INSTANCE_ID" --region "$AWS_REGION" --output text > /dev/null

echo "Waiting for running state..."
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --region "$AWS_REGION"

IP=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --region "$AWS_REGION" \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

echo ""
echo "✓ Instance running"
echo "  IP        : $IP"
echo "  SSH       : ssh -i ~/.ssh/hermes-ai-key ubuntu@$IP"
echo "  Hermes    : http://$IP:8642"
echo ""
echo "Note: if this is a fresh instance, install services manually."
echo "Or get user_data.sh in the full Blueprint: https://your-gumroad-link"
