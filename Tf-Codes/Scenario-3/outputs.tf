output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.vpc01.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.igw.id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = aws_nat_gateway.nat.id
}

output "public_instance_id" {
  description = "Public EC2 instance id"
  value       = aws_instance.public_ec2.id
}

output "public_instance_public_ip" {
  description = "Public EC2 public IP"
  value       = aws_instance.public_ec2.public_ip
}

output "private_asg_name" {
  description = "Private autoscaling group name"
  value       = aws_autoscaling_group.private_asg.name
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.app_alb.dns_name
}

output "generated_key_name" {
  description = "Generated AWS key pair name"
  value       = aws_key_pair.generated.key_name
}
