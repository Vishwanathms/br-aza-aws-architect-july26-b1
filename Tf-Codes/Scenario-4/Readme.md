
# Scenario-4: 3-Tier Application Architecture with Modular Terraform

## Architecture Overview

This scenario implements a modular 3-tier application architecture:

```
Internet → ALB → Nginx ASG (Private) → Python App (Private) → Redis DB (Database Tier)
```

### Infrastructure Layers

1. **Public Tier (ALB)**
   - Application Load Balancer in public subnets
   - Handles incoming HTTP traffic

2. **Application Tier**
   - **Nginx Web Servers**: Auto Scaling Group (min: 1, max: 3, desired: 1)
     - Acts as reverse proxy to Python app
     - CPU-based autoscaling at 70% threshold
   - **Python Flask App**: Single EC2 instance
     - Runs on port 5000
     - Connects to Redis for caching
     - Includes health check endpoint

3. **Database Tier**
   - **Redis Database**: Single EC2 instance
     - Isolated in database subnet
     - No internet access via NAT
     - Serves as cache for Python app

## Network Architecture

### Subnets (per AZ us-east-1a, us-east-1b)
- **Public Subnets** (10.0.0.0/24, 10.0.1.0/24)
  - IGW route to internet
  - ALB placement

- **Private Application Subnets** (10.0.2.0/24, 10.0.3.0/24)
  - NAT Gateway route to internet
  - Nginx and Python instances

- **Database Subnets** (10.0.4.0/24, 10.0.5.0/24)
  - No internet route (isolated)
  - Redis DB instance

## Module Structure

### VPC_Netwrk Module
Handles all networking components:
- VPC with IGW
- Public, private, and database subnets
- NAT Gateway in public subnet
- Route tables and associations
- **Files:**
  - `main.tf` - VPC and subnet resources
  - `variables.tf` - Input variables
  - `outputs.tf` - Network outputs (VPC ID, subnet IDs, etc.)

### Application-Setup Module
Implements the 3-tier application:
- Security groups with proper ingress rules
- SSH key generation
- IAM role for Systems Manager
- ALB with target group
- Nginx launch template and ASG
- Python Flask app EC2
- Redis database EC2
- User data scripts for all instances
- **Files:**
  - `main.tf` - All application resources
  - `variables.tf` - Input variables
  - `outputs.tf` - Application outputs

## Root Configuration

- `main.tf` - Module instantiation
- `variables.tf` - Root variables passed to modules
- `outputs.tf` - Consolidated outputs from both modules
- `provider.tf` - AWS provider configuration
- `terraform.tfvars` - Default variable values
- `versions.tf` - Terraform and provider versions

## User Data Scripts

### Nginx Configuration
- Installs nginx and SSM agent
- Configures reverse proxy to Python app on port 5000
- Auto-detects Python app IP

### Python Application
- Installs Python3, Flask, and Redis client
- Creates Flask app with `/` and `/health` endpoints
- Connects to Redis for caching
- Runs on port 5000

### Redis Database
- Installs and enables Redis server
- Configures to listen on all interfaces (0.0.0.0)
- Accessible on port 6379

## Security Groups

| SG Name | Port | Source | Purpose |
|---------|------|--------|---------|
| ALB SG | 80 | 0.0.0.0/0 | Public HTTP access |
| Nginx SG | 80 | ALB SG | ALB to Nginx |
| Nginx SG | 22 | 0.0.0.0/0 | SSH access |
| Python SG | 5000 | Nginx SG | Nginx to Python |
| Python SG | 22 | 0.0.0.0/0 | SSH access |
| Redis SG | 6379 | Python SG | Python to Redis |
| Redis SG | 22 | 0.0.0.0/0 | SSH access |

## Deployment Instructions

```bash
cd Scenario-4
terraform init
terraform plan
terraform apply
```

## Key Features

✓ Modular structure for maintainability
✓ Separate network and application modules
✓ Database tier isolation
✓ Auto-scaling Nginx tier
✓ Complete 3-tier application setup via user data
✓ Proper security group chaining
✓ Systems Manager access for all instances
✓ Automatic SSH key generation and storage 

Architecture diagram:
- Open scenario-3-architecture.svg in your browser or VS Code preview to view the visual layout.



