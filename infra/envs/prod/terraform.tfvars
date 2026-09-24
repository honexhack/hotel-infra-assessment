environment = "prod"
aws_region  = "ap-south-1"

vpc_cidr = "10.20.0.0/16"
azs      = ["ap-south-1a", "ap-south-1b"]

app_cpu           = 512
app_memory        = 1024
app_desired_count = 2

db_instance_class        = "db.t4g.medium"
db_allocated_storage     = 50
db_multi_az              = true
db_backup_retention_days = 14
db_deletion_protection   = true
db_skip_final_snapshot   = false
