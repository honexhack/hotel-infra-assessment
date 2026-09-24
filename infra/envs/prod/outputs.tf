output "alb_dns_name" {
  value = module.ecs.alb_dns_name
}

output "db_endpoint" {
  value = module.rds.db_endpoint
}
