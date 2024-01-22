##############################################################################################################
# Terraform Providers
##############################################################################################################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = local.region
  assume_role {
    role_arn    = "arn:aws:iam::${local.account_id}:role/role-${local.tags["Owner"]}"
    external_id = local.externalid_token
  }
}

# Access and secret keys to your environment
variable "access_key" {}
variable "secret_key" {}