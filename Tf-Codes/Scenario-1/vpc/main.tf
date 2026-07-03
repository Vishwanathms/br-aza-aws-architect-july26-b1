locals {
  name_prefix = var.vpc_name
}

resource "aws_vpc" "vpc01" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(var.tags, { Name = local.name_prefix })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc01.id
  tags = merge(var.tags, { Name = "${local.name_prefix}-igw" })
}

data "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.vpc01.default_route_table_id
}

resource "aws_route" "default_internet" {
  route_table_id         = data.aws_default_route_table.default.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_subnet" "public" {
#   for_each = { for idx, cidr in var.public_subnets_cidrs : tostring(idx) => {
#     cidr = cidr
#     az   = var.azs[idx]
#   } }
  count = length(var.public_subnets_cidrs)  
  vpc_id                  = aws_vpc.vpc01.id
  cidr_block              = var.public_subnets_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true
  tags = merge(var.tags, { Name = "${local.name_prefix}-public-Sub${count.index}" })
}

resource "aws_subnet" "private" {
  count = length(var.private_subnets_cidrs)
  vpc_id            = aws_vpc.vpc01.id
  cidr_block        = var.private_subnets_cidrs[count.index]
  availability_zone = var.azs[count.index]
  tags = merge(var.tags, { Name = "${local.name_prefix}-private-Sub${count.index}" })
}

# Associate public subnets to the VPC's default route table
resource "aws_route_table_association" "public_assoc" {
  count = length(aws_subnet.public)

  route_table_id = data.aws_default_route_table.default.id
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
  tags = merge(var.tags, { Name = "${local.name_prefix}-nat" })
  depends_on = [aws_internet_gateway.igw]
}

# New route table for private subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc01.id
  tags = merge(var.tags, { Name = "${local.name_prefix}-private-rt" })
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

# Lookup latest Amazon Linux 3 AMI
data "aws_ami" "amazon_linux_3" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn3-ami-hvm-*-x86_64-gp2"]
  }
}

# Security Group allowing SSH, HTTP and ICMP
resource "aws_security_group" "web_sg" {
  name   = "${local.name_prefix}-web-sg"
  vpc_id = aws_vpc.vpc01.id

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "ICMP"
    from_port        = -1
    to_port          = -1
    protocol         = "icmp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    description      = "all"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.name_prefix}-web-sg" })
}

# Generate an SSH keypair and upload public key to AWS
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated" {
  key_name   = "${var.key_name_prefix}-${random_id.key_suffix.hex}"
  public_key = tls_private_key.key.public_key_openssh
}

resource "random_id" "key_suffix" {
  byte_length = 4
}

# Optionally save private key to local file
resource "local_file" "private_key" {
  count    = var.save_private_key ? 1 : 0
  filename = var.private_key_path
  content  = tls_private_key.key.private_key_pem
  file_permission = "0600"
}

# EC2 instances
resource "aws_instance" "public_ec2" {
  ami                    = data.aws_ami.amazon_linux_3.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[0].id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = aws_key_pair.generated.key_name
  tags = merge(var.tags, { Name = "${local.name_prefix}-public-ec2" })
}

resource "aws_instance" "private_ec2" {
  ami                    = data.aws_ami.amazon_linux_3.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private[0].id
  associate_public_ip_address = false
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = aws_key_pair.generated.key_name
  tags = merge(var.tags, { Name = "${local.name_prefix}-private-ec2" })
}
