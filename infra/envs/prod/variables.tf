variable "environment" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "plan_only" {
  description = "Use mock credentials so plan works without an AWS account"
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "container_image" {
  type    = string
  default = "nginx:1.27-alpine"
}

variable "app_cpu" {
  type = number
}

variable "app_memory" {
  type = number
}

variable "app_desired_count" {
  type = number
}

variable "db_instance_class" {
  type = string
}

variable "db_allocated_storage" {
  type = number
}

variable "db_multi_az" {
  type = bool
}

variable "db_backup_retention_days" {
  type = number
}

variable "db_deletion_protection" {
  type = bool
}

variable "db_skip_final_snapshot" {
  type = bool
}
