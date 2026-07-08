# Scenario-3: Public EC2 + Private Auto Scaling Group behind ALB

## Overview
This scenario upgrades the private tier from standalone EC2 instances to an Auto Scaling Group while keeping one public EC2 instance and the ALB in place.

## What is created
- One VPC
- Two public subnets
- Two private subnets
- Internet Gateway and NAT Gateway
- One public EC2 instance in a public subnet
- A private Auto Scaling Group for web application instances
- An Application Load Balancer
- A target group attached to the autoscaling group
- IAM role and instance profile for Systems Manager
- Security groups for web traffic and ALB access
- User data that installs HTTPD and serves the hostname on the web page

## Architecture flow
```text
Internet → ALB → Private Auto Scaling Group → EC2 instances
```

## Key features
- Maintains one public EC2 instance for direct access
- Replaces the two private instances with an autoscaling group
- Uses a target tracking policy based on CPU utilization
- Supports horizontal scaling for the private web tier
- Keeps the ALB and target group active for traffic distribution

## Files in this folder
- main.tf: VPC and network resources
- ec2.tf: public EC2, launch template, autoscaling group, and scaling policy
- alb.tf: ALB, target group, and listener
- variables.tf and terraform.tfvars: configuration inputs
- outputs.tf: key deployment outputs

## Typical deployment
```bash
cd Scenario-3
terraform init
terraform plan
terraform apply
```

## Diagram
- Open [scenario-3-architecture.svg](scenario-3-architecture.svg) in your browser or VS Code preview to view the visual layout.



