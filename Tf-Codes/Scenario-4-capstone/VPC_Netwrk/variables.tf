variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "vpc_name" {
  description = "Name prefix for the VPC and related resources"
  type        = string
  default     = "demo-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "List of Availability Zones to use (order matters for subnet placement)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets_cidrs" {
  description = "CIDR blocks for public subnets (two items)"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnets_cidrs" {
  description = "CIDR blocks for private subnets (two items)"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.3.0/24"]
}

variable "db_subnets_cidrs" {
  description = "CIDR blocks for database subnets (two items)"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24"]
}

variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = { Owner = "devops" }
}
