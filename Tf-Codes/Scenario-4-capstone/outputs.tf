# ===== VPC Network Outputs =====
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc_network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc_network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private application subnets"
  value       = module.vpc_network.private_subnet_ids
}

output "db_subnet_ids" {
  description = "IDs of database subnets"
  value       = module.vpc_network.db_subnet_ids
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = module.vpc_network.internet_gateway_id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = module.vpc_network.nat_gateway_id
}

# ===== Application Setup Outputs =====
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.application_setup.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.application_setup.alb_arn
}

output "nginx_asg_name" {
  description = "Name of the Nginx autoscaling group"
  value       = module.application_setup.nginx_asg_name
}

output "python_app_private_ip" {
  description = "Private IP of Python application EC2"
  value       = module.application_setup.python_app_private_ip
}

output "redis_db_private_ip" {
  description = "Private IP of Redis database EC2"
  value       = module.application_setup.redis_db_private_ip
}

output "generated_key_name" {
  description = "Generated AWS key pair name"
  value       = module.application_setup.generated_key_name
}
