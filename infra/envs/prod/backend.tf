terraform {
  # Local state so this can be planned without an AWS account.
  # Real setup would use S3:
  #
  # backend "s3" {
  #   bucket       = "hotel-terraform-state"
  #   key          = "prod/terraform.tfstate"
  #   region       = "ap-south-1"
  #   use_lockfile = true
  # }

  backend "local" {
    path = "terraform.tfstate"
  }
}
