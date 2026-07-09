output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.vpc01.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private application subnets"
  value       = aws_subnet.private[*].id
}

output "db_subnet_ids" {
  description = "IDs of database subnets"
  value       = aws_subnet.db[*].id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.igw.id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = aws_nat_gateway.nat.id
}

output "vpc_name_prefix" {
  description = "Name prefix used for resources"
  value       = local.name_prefix
}
