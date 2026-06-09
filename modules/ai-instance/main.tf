# ── AMI ───────────────────────────────────────────────────────────────────────
# Full Blueprint uses a pinned, tested Ubuntu 24.04 AMI data source.
# This free tier version uses a static AMI ID — update for your region.
# Ubuntu 24.04 LTS AMI IDs by region (as of 2025):
#   eu-central-1 : ami-0faab6bdbac9486fb
#   eu-west-1    : ami-0905a3c97561e0b69
#   us-east-1    : ami-0866a3c8686eaeeba
#
# Always verify current AMI at: https://cloud-images.ubuntu.com/locator/ec2/
locals {
  ami_map = {
    "eu-central-1" = "ami-0faab6bdbac9486fb"
    "eu-west-1"    = "ami-0905a3c97561e0b69"
    "us-east-1"    = "ami-0866a3c8686eaeeba"
  }
  ami_id = lookup(local.ami_map, var.region, "ami-0faab6bdbac9486fb")
}

# ── SSH Key ───────────────────────────────────────────────────────────────────
resource "aws_key_pair" "ai_key" {
  key_name   = "${var.client_name}-ai-key"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

# ── Security Group ────────────────────────────────────────────────────────────
# ⚠️  Restricted to your IP only. Set my_ip in terraform.tfvars.
# Full Blueprint adds VPC isolation and stricter egress rules.
resource "aws_security_group" "ai_sg" {
  name        = "${var.client_name}-ai-sg"
  description = "Private AI Circuit — SSH and Hermes Gateway"

  ingress {
    description = "SSH from operator IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  ingress {
    description = "Hermes Remote Gateway"
    from_port   = 8642
    to_port     = 8642
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.client_name}-ai-sg"
    Project = "private-ai-circuit"
  }
}

# ── IAM ───────────────────────────────────────────────────────────────────────
resource "aws_iam_role" "ai_role" {
  name = "${var.client_name}-ai-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = { Project = "private-ai-circuit" }
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ai_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ai_profile" {
  name = "${var.client_name}-ai-profile"
  role = aws_iam_role.ai_role.name
}

# ── EC2 Instance ──────────────────────────────────────────────────────────────
# Note: user_data is not included in the free tier.
# After deploy, you'll have a blank Ubuntu 24.04 instance.
# Manual setup guide: https://github.com/BaibakovDmytro/private-ai-circuit/wiki/Manual-Setup
resource "aws_instance" "ai_gpu" {
  ami                    = local.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ai_key.key_name
  vpc_security_group_ids = [aws_security_group.ai_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ai_profile.name

  root_block_device {
    volume_size = var.volume_size_gb
    volume_type = "gp3"
    iops        = 3000
    encrypted   = true
  }

  # user_data intentionally omitted in free tier
  # Full Blueprint auto-installs: NVIDIA driver 550, Docker, Ollama, Hermes Gateway
  # Get it here: https://payhip.com/b/nkpSv

  metadata_options {
    http_tokens = "required"  # IMDSv2 only — security best practice
  }

  tags = {
    Name    = "${var.client_name}-private-ai-gpu"
    Project = "private-ai-circuit"
    Tier    = "free"
  }
}

# ── Auto-stop (CloudWatch Alarm) ──────────────────────────────────────────────
# ⚠️  Free tier limitation: triggers on CPU utilization.
#     On GPU instances, the model runs on GPU — CPU stays low even when busy.
#     This may cause false-positive stops during active inference.
#
#     Full Blueprint uses GPU utilization metric via CloudWatch Agent
#     (namespace: PrivateAI/Instance, metric: GPUUtilization)
resource "aws_cloudwatch_metric_alarm" "idle_stop" {
  count = var.auto_stop_enabled ? 1 : 0

  alarm_name          = "${var.client_name}-ai-idle-stop"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.idle_minutes * 60
  statistic           = "Average"
  threshold           = var.low_cpu_threshold

  dimensions = {
    InstanceId = aws_instance.ai_gpu.id
  }

  alarm_description = "Stop instance when CPU idle (free tier — may false-trigger on GPU workloads)"
  alarm_actions     = [aws_lambda_function.auto_stop[0].arn]
}

# ── Lambda auto-stop ──────────────────────────────────────────────────────────
# Creates a minimal inline Lambda to stop the instance.
# Full Blueprint includes: graceful service shutdown, session save, SNS notification.
resource "aws_lambda_function" "auto_stop" {
  count = var.auto_stop_enabled ? 1 : 0

  filename         = "${path.module}/lambda-auto-stop.zip"
  function_name    = "${var.client_name}-ai-autostop"
  role             = aws_iam_role.lambda_stop[0].arn
  handler          = "auto_stop.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30
  source_code_hash = filebase64sha256("${path.module}/lambda-auto-stop.zip")

  environment {
    variables = {
      INSTANCE_ID = aws_instance.ai_gpu.id
      REGION      = var.region
    }
  }

  tags = { Project = "private-ai-circuit" }
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  count = var.auto_stop_enabled ? 1 : 0

  statement_id  = "AllowCloudWatchAlarm"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auto_stop[0].function_name
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"
  source_arn    = aws_cloudwatch_metric_alarm.idle_stop[0].arn
}

# Least-privilege IAM for Lambda (stops only this specific instance)
resource "aws_iam_role" "lambda_stop" {
  count = var.auto_stop_enabled ? 1 : 0
  name  = "${var.client_name}-ai-autostop-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_stop_inline" {
  count = var.auto_stop_enabled ? 1 : 0
  name  = "stop-specific-instance"
  role  = aws_iam_role.lambda_stop[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ec2:StopInstances"]
        Resource = "arn:aws:ec2:${var.region}:*:instance/${aws_instance.ai_gpu.id}"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}
