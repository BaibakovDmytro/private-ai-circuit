variable "client_name" {
  description = "Project name prefix"
  type        = string
}

variable "my_ip" {
  description = "Your public IP — used to restrict Security Group ingress"
  type        = string
}

variable "instance_type" {
  description = "EC2 GPU instance type"
  type        = string
}

variable "volume_size_gb" {
  description = "Root EBS volume size in GB"
  type        = number
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "auto_stop_enabled" {
  description = "Enable CloudWatch alarm + Lambda auto-stop"
  type        = bool
  default     = true
}

variable "low_cpu_threshold" {
  description = "CPU utilization (%) below which instance is considered idle"
  type        = number
  default     = 8
}

variable "idle_minutes" {
  description = "Minutes below threshold before auto-stop triggers"
  type        = number
  default     = 25
}
