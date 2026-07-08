# Scenario-1: Basic VPC and EC2 Deployment

## Overview
This scenario creates a simple AWS networking and compute setup with one public EC2 instance and one private EC2 instance.

## What is created
- One VPC
- Two public subnets
- Two private subnets
- One Internet Gateway
- One NAT Gateway
- Route tables and subnet associations
- One public EC2 instance in a public subnet
- One private EC2 instance in a private subnet
- Security groups allowing SSH, HTTP, and ICMP
- SSH key pair generation
- Optional local private key file storage

## Network layout
- Public subnets are attached to the default route table
- Private subnets use a separate route table with a route to the NAT Gateway
- Internet access is provided to public resources through the IGW

## EC2 setup
- Both instances use the same key pair and security group configuration
- The public instance is assigned a public IP
- The private instance remains private and uses the NAT path for outbound traffic

## Files in this folder
- main.tf: core VPC and networking resources
- variables.tf: configurable input values
- terraform.tfvars: sample values for deployment
- outputs.tf: useful outputs such as VPC and instance IDs
- provider.tf and versions.tf: provider and Terraform version setup

## Typical deployment
```bash
cd Scenario-1
terraform init
terraform plan
terraform apply
```
