terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment to store state in S3 (recommended for teams)
  # Full Blueprint includes a Terraform module to provision the S3 bucket + DynamoDB lock table.
  #
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "private-ai-circuit/terraform.tfstate"
  #   region         = "eu-central-1"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}
