# ===== Module: VPC and Network Infrastructure =====
module "vpc_network" {
  source = "./VPC_Netwrk"

  vpc_name              = var.vpc_name
  vpc_cidr              = var.vpc_cidr
  azs                   = var.azs
  public_subnets_cidrs  = var.public_subnets_cidrs
  private_subnets_cidrs = var.private_subnets_cidrs
  db_subnets_cidrs      = var.db_subnets_cidrs
  tags                  = var.tags
}

# ===== Module: Application Setup (3-tier) =====
module "application_setup" {
  source = "./Application-Setup"

  vpc_id             = module.vpc_network.vpc_id
  vpc_name           = var.vpc_name
  public_subnet_ids  = module.vpc_network.public_subnet_ids
  private_subnet_ids = module.vpc_network.private_subnet_ids
  db_subnet_ids      = module.vpc_network.db_subnet_ids
  instance_type      = var.instance_type
  key_name_prefix    = var.key_name_prefix
  save_private_key   = var.save_private_key
  private_key_path   = var.private_key_path
  tags               = var.tags
}
