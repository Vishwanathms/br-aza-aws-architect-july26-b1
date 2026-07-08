variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_name" {
  description = "Name prefix for resources"
  type        = string
  default     = "demo-vpc"
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for nginx ASG and Python app"
  type        = list(string)
}

variable "db_subnet_ids" {
  description = "Database subnet IDs for Redis"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name_prefix" {
  description = "Prefix for generated key pair name"
  type        = string
  default     = "example-key"
}

variable "save_private_key" {
  description = "Whether to write the generated private key to a local file"
  type        = bool
  default     = true
}

variable "private_key_path" {
  description = "Local path to write the private key"
  type        = string
  default     = "./id_rsa_example.pem"
}

variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = { Owner = "devops" }
}
