output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "alb_dns_name" {
  description = "Application load balancer DNS name"
  value       = module.ecs.alb_dns_name
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "rds_endpoint" {
  description = "RDS endpoint (sensitive)"
  value       = module.rds.db_endpoint
  sensitive   = true
}

output "rds_port" {
  description = "RDS port"
  value       = module.rds.db_port
}

output "ecs_log_group_name" {
  description = "CloudWatch log group for ECS tasks"
  value       = module.ecs.log_group_name
}

output "nat_gateway_ids" {
  description = "NAT gateway IDs in the VPC"
  value       = module.network.nat_gateway_ids
}
