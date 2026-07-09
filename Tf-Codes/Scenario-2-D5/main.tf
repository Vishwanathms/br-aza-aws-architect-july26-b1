locals {
  name_prefix = var.vpc_name
}

resource "aws_vpc" "vpc01" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = local.name_prefix })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc01.id
  tags   = merge(var.tags, { Name = "${local.name_prefix}-igw" })
}


resource "aws_route" "default_internet" {
  route_table_id         = aws_vpc.vpc01.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_subnet" "public" {
  #   for_each = { for idx, cidr in var.public_subnets_cidrs : tostring(idx) => {
  #     cidr = cidr
  #     az   = var.azs[idx]
  #   } }
  count                   = length(var.public_subnets_cidrs)
  vpc_id                  = aws_vpc.vpc01.id
  cidr_block              = var.public_subnets_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true
  tags                    = merge(var.tags, { Name = "${local.name_prefix}-public-Sub${count.index}" })
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnets_cidrs)
  vpc_id            = aws_vpc.vpc01.id
  cidr_block        = var.private_subnets_cidrs[count.index]
  availability_zone = var.azs[count.index]
  tags              = merge(var.tags, { Name = "${local.name_prefix}-private-Sub${count.index}" })
}

# Associate public subnets to the VPC's default route table
resource "aws_route_table_association" "public_assoc" {
  count = length(aws_subnet.public)

  route_table_id = aws_vpc.vpc01.default_route_table_id
  subnet_id      = aws_subnet.public[count.index].id
}

# Private setup, including NAT Gateway and private route table

# Elastic IP for NAT
resource "aws_eip" "nat" {
  tags = merge(var.tags, { Name = "${local.name_prefix}-nat-eip" })
}

# NAT Gateway in public subnet with key "0" (sub1)
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags          = merge(var.tags, { Name = "${local.name_prefix}-nat" })
  depends_on    = [aws_internet_gateway.igw]
}

# New route table for private subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc01.id
  tags   = merge(var.tags, { Name = "${local.name_prefix}-private-rt" })
}

resource "aws_route" "private_default_route" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# Associate private subnets to the new private route table
resource "aws_route_table_association" "private_assoc" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
