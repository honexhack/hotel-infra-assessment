provider "aws" {
  region = var.aws_region

  access_key                  = var.plan_only ? "mock-access-key" : null
  secret_key                  = var.plan_only ? "mock-secret-key" : null
  skip_credentials_validation = var.plan_only
  skip_requesting_account_id  = var.plan_only
  skip_metadata_api_check     = var.plan_only

  default_tags {
    tags = {
      Project     = "hotel"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

locals {
  name = "hotel-${var.environment}"
}

module "network" {
  source = "../../modules/network"

  name     = local.name
  vpc_cidr = var.vpc_cidr
  azs      = var.azs
}
