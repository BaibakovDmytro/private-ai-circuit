variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"

  validation {
    condition     = contains(["eu-central-1", "eu-west-1", "us-east-1", "us-west-2"], var.region)
    error_message = "Region must be one of: eu-central-1, eu-west-1, us-east-1, us-west-2."
  }
}

variable "client_name" {
  description = "Project name — used as prefix for all AWS resource names"
  type        = string
  default     = "private-ai"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,20}$", var.client_name))
    error_message = "client_name must be 3–20 lowercase letters, numbers, or hyphens."
  }
}

variable "my_ip" {
  description = "Your public IP address — restricts SSH and Hermes port access. Find it: curl ifconfig.me"
  type        = string

  validation {
    condition     = can(regex("^(\\d{1,3}\\.){3}\\d{1,3}$", var.my_ip)) && var.my_ip != "0.0.0.0"
    error_message = "my_ip must be a valid IPv4 address (not 0.0.0.0). Run: curl ifconfig.me"
  }
}

variable "ssh_public_key_path" {
  description = <<-EOT
    Path to your SSH public key file.
    Linux/Mac : ~/.ssh/hermes-ai-key.pub
    Windows   : C:/Users/YourName/.ssh/hermes-ai-key.pub

    Generate with:
      Linux/Mac : ssh-keygen -t ed25519 -f ~/.ssh/hermes-ai-key
      Windows   : ssh-keygen -t ed25519 -f $env:USERPROFILE\.ssh\hermes-ai-key
  EOT
  type        = string
  default     = "~/.ssh/hermes-ai-key.pub"
}

variable "instance_type" {
  description = "EC2 GPU instance type"
  type        = string
  default     = "g4dn.xlarge"

  validation {
    condition     = contains(["g4dn.xlarge", "g5.xlarge", "g5.4xlarge", "g5.2xlarge", "g6.xlarge"], var.instance_type)
    error_message = "instance_type must be a GPU instance: g4dn.xlarge, g5.xlarge, g5.4xlarge, g5.2xlarge, or g6.xlarge."
  }
}

variable "volume_size_gb" {
  description = "Root EBS volume size in GB. 80GB fits 2–3 models; 120GB fits 4–5."
  type        = number
  default     = 80

  validation {
    condition     = var.volume_size_gb >= 60 && var.volume_size_gb <= 500
    error_message = "volume_size_gb must be between 60 and 500."
  }
}

variable "auto_stop_enabled" {
  description = "Enable automatic shutdown when instance is idle"
  type        = bool
  default     = true
}

variable "low_cpu_threshold" {
  description = "CPU utilization (%) below which the instance is considered idle."
  type        = number
  default     = 8

  validation {
    condition     = var.low_cpu_threshold >= 1 && var.low_cpu_threshold <= 50
    error_message = "low_cpu_threshold must be between 1 and 50."
  }
}

variable "idle_minutes" {
  description = "Minutes below threshold before auto-stop triggers. Actual wait = idle_minutes × 2."
  type        = number
  default     = 25

  validation {
    condition     = var.idle_minutes >= 5 && var.idle_minutes <= 120
    error_message = "idle_minutes must be between 5 and 120."
  }
}
