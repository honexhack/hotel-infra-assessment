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

module "ecs" {
  source = "../../modules/ecs"

  name               = local.name
  aws_region         = var.aws_region
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  container_image    = var.container_image
  cpu                = var.app_cpu
  memory             = var.app_memory
  desired_count      = var.app_desired_count
}

module "rds" {
  source = "../../modules/rds"

  name                    = local.name
  vpc_id                  = module.network.vpc_id
  private_subnet_ids      = module.network.private_subnet_ids
  app_security_group_id   = module.ecs.app_security_group_id
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  multi_az                = var.db_multi_az
  backup_retention_period = var.db_backup_retention_days
  deletion_protection     = var.db_deletion_protection
  skip_final_snapshot     = var.db_skip_final_snapshot
}
