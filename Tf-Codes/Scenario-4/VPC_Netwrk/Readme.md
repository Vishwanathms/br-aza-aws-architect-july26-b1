# VPC_Netwrk Module

This module creates the complete networking foundation for Scenario-4.

## Resources included
- VPC
- Internet Gateway
- Public subnets
- Private application subnets
- Database subnets
- NAT Gateway
- Route tables and associations

## Purpose
This module provides the network layer for the 3-tier application:
- Public subnets for the Application Load Balancer
- Private subnets for the Nginx and Python tiers
- Database subnets for Redis isolation

## Outputs
- VPC ID
- Public subnet IDs
- Private subnet IDs
- Database subnet IDs
- Internet Gateway ID
- NAT Gateway ID
