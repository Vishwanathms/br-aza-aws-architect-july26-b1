output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.app_alb.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.app_alb.arn
}

output "nginx_asg_name" {
  description = "Name of the Nginx autoscaling group"
  value       = aws_autoscaling_group.nginx_asg.name
}

output "python_app_private_ip" {
  description = "Private IP of Python application EC2"
  value       = aws_instance.python_app.private_ip
}

output "redis_db_private_ip" {
  description = "Private IP of Redis database EC2"
  value       = aws_instance.redis_db.private_ip
}

output "generated_key_name" {
  description = "Generated AWS key pair name"
  value       = aws_key_pair.generated.key_name
}

output "nginx_target_group_arn" {
  description = "ARN of the Nginx target group"
  value       = aws_lb_target_group.nginx_tg.arn
}
