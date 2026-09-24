environment = "dev"
aws_region  = "ap-south-1"

vpc_cidr = "10.10.0.0/16"
azs      = ["ap-south-1a", "ap-south-1b"]

app_cpu           = 256
app_memory        = 512
app_desired_count = 1

db_instance_class        = "db.t4g.micro"
db_allocated_storage     = 20
db_multi_az              = false
db_backup_retention_days = 1
db_deletion_protection   = false
db_skip_final_snapshot   = true
