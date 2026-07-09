# Scenario-2: VPC with Public EC2 and Private Tier behind ALB

## Overview
This scenario extends the basic networking setup by adding a public EC2 instance, two private EC2 instances, and an Application Load Balancer in front of the private tier.

## What is created
- One VPC
- Two public subnets
- Two private subnets
- Internet Gateway and NAT Gateway
- A public EC2 instance in the public subnet
- Two private EC2 instances, one in each private subnet
- IAM role and instance profile for AWS Systems Manager
- Security groups for web access and ALB traffic
- An Application Load Balancer
- A target group attached to the private instances
- HTTPD installation using user data on the EC2 instances

## Architecture flow
```text
Internet → ALB → Private EC2 instances
```

## Key features
- Public web access is handled by the ALB
- Private instances host web content via HTTPD
- SSM is configured for management of all EC2 instances
- User data provides different index.html content per instance

## Files in this folder
- main.tf: network infrastructure
- ec2.tf: EC2 instances, IAM, and user data
- alb.tf: ALB, target group, and listener
- variables.tf: configurable variables
- outputs.tf: deployment outputs

## Typical deployment
```bash
cd Scenario-2
terraform init
terraform plan
terraform apply
```


