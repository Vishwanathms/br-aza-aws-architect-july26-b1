aws_region            = "us-east-1"
vpc_name              = "my-vpc"
vpc_cidr              = "10.0.0.0/16"
azs                   = ["us-east-1a", "us-east-1b"]
public_subnets_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
private_subnets_cidrs = ["10.0.2.0/24", "10.0.3.0/24"]
tags = {
  Owner       = "team-a"
  Environment = "dev"
  Terraform   = "true"
}
instance_type    = "t3.micro"
key_name_prefix  = "key2"
save_private_key = true
private_key_path = "./key2.pem"
