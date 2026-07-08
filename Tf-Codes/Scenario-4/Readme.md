
# Scenario-4: 3-Tier Application Architecture with Modular Terraform

## Overview

This scenario creates a complete 3-tier web application stack on AWS using Terraform modules.

Traffic flow:

```text
Internet → Application Load Balancer → Nginx Auto Scaling Group → Python App EC2 → Redis EC2
```

---

## What is created

### 1. Networking layer
The VPC network module creates:
- One VPC
- One Internet Gateway
- Two public subnets
- Two private application subnets
- Two database subnets
- One NAT Gateway
- Route tables and subnet associations

### 2. Public access layer
The public tier includes:
- An Application Load Balancer (ALB)
- A public-facing security group for HTTP access
- A target group for the Nginx tier

### 3. Application tier
The application tier includes:
- An Nginx Auto Scaling Group
  - Min size: 1
  - Desired capacity: 1
  - Max size: 3
  - Uses a launch template
  - Scales based on CPU utilization target of 70%
- One Python EC2 instance running a Flask application
  - Runs on port 5000
  - Connects to Redis
  - Exposes `/` and `/health` endpoints

### 4. Database tier
The database tier includes:
- One Redis EC2 instance
- A dedicated database subnet
- A Redis security group allowing only the Python app to connect

### 5. Management and security
The deployment also creates:
- An IAM role for AWS Systems Manager
- An instance profile attached to EC2 instances
- An SSH key pair
- An optional private key file stored locally
- Security groups for ALB, Nginx, Python, and Redis

---

## Module structure

### VPC_Netwrk module
This module handles all network resources:
- VPC and Internet Gateway
- Public, private, and DB subnets
- NAT Gateway
- Route tables and associations

### Application-Setup module
This module handles the full application stack:
- ALB and target group
- Nginx launch template and autoscaling group
- Python app EC2
- Redis DB EC2
- Security groups and IAM setup
- User data scripts for software installation

---

## User data setup

### Nginx instances
- Install nginx
- Install amazon-ssm-agent
- Start SSM agent
- Configure reverse proxy to the Python app

### Python app instance
- Install Python 3, pip, Flask, and Redis client
- Start a Flask app on port 5000
- Connect to Redis

### Redis instance
- Install Redis
- Enable and start the Redis service
- Configure it to listen on all interfaces

---

## Security groups created

| Component | Ports | Source | Purpose |
|---|---:|---|---|
| ALB SG | 80 | 0.0.0.0/0 | Public HTTP access |
| Nginx SG | 80 | ALB SG | ALB to Nginx |
| Nginx SG | 22 | 0.0.0.0/0 | SSH access |
| Python SG | 5000 | Nginx SG | Nginx to Python |
| Python SG | 22 | 0.0.0.0/0 | SSH access |
| Redis SG | 6379 | Python SG | Python to Redis |
| Redis SG | 22 | 0.0.0.0/0 | SSH access |

---

## Outputs from the deployment

The configuration provides outputs for:
- VPC ID
- Public subnet IDs
- Private subnet IDs
- Database subnet IDs
- Internet Gateway ID
- NAT Gateway ID
- ALB DNS name
- Nginx autoscaling group name
- Python app private IP
- Redis private IP
- Generated key pair name

---

## Deployment flow

Run:

```bash
cd Scenario-4
terraform init
terraform plan
terraform apply
```

---

## Summary

Scenario-4 provisions a complete, modular AWS 3-tier architecture with:
- Public web entry through an ALB
- Private application hosting through an autoscaled Nginx tier
- A dedicated Python application server
- A Redis database server in isolated DB subnets
- Security groups, IAM access, and SSM support for all EC2 instances

Architecture diagram:
- Open [scenario-4-architecture.svg](scenario-4-architecture.svg) in your browser or VS Code preview to view the visual layout.



