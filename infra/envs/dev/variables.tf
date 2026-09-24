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