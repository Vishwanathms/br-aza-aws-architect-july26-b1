# Application-Setup Module

This module deploys the 3-tier application for Scenario-4.

## Architecture
Internet -> ALB -> Nginx ASG -> Python EC2 -> Redis EC2

## Resources included
- Application Load Balancer
- Target Group
- Nginx Auto Scaling Group
- Python Flask EC2 instance
- Redis EC2 instance
- Security groups
- IAM role/profile for SSM
- SSH key generation

## User data
- Nginx installs nginx and acts as a reverse proxy to the Python app
- Python installs Flask and connects to Redis
- Redis installs and configures the Redis service

## Outputs
- ALB DNS name
- ALB ARN
- Nginx ASG name
- Python app private IP
- Redis private IP
- Generated key name
