
# Lookup latest Amazon Linux 3 AMI
data "aws_ami" "amazon_linux_3" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

# Security Group allowing SSH, HTTP and ICMP
resource "aws_security_group" "web_sg" {
  name   = "${local.name_prefix}-web-sg"
  vpc_id = aws_vpc.vpc01.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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
  count           = var.save_private_key ? 1 : 0
  filename        = var.private_key_path
  content         = tls_private_key.key.private_key_pem
  file_permission = "0600"
}

# IAM role for Systems Manager
resource "aws_iam_role" "ssm_role" {
  name = "${local.name_prefix}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, { Name = "${local.name_prefix}-ssm-role" })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${local.name_prefix}-ssm-profile"
  role = aws_iam_role.ssm_role.name
}


# EC2 instances
resource "aws_instance" "public_ec2" {
  ami                         = data.aws_ami.amazon_linux_3.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  key_name                    = aws_key_pair.generated.key_name
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
  user_data                   = <<-EOF
    #!/bin/bash
    dnf install -y amazon-ssm-agent httpd
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
    systemctl enable httpd
    systemctl start httpd
    cat > /var/www/html/index.html <<HTML
    <html>
      <body>
        <h1>Host: $(hostname -f)</h1>
      </body>
    </html>
    HTML
  EOF
  tags                        = merge(var.tags, { Name = "${local.name_prefix}-public-ec2" })
}

resource "aws_launch_template" "app_lt" {
  name_prefix            = "${local.name_prefix}-app-lt-"
  image_id               = data.aws_ami.amazon_linux_3.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.generated.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ssm_profile.name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf install -y amazon-ssm-agent httpd
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
    systemctl enable httpd
    systemctl start httpd
    cat > /var/www/html/index.html <<HTML
    <html>
      <body>
        <h1>Host: $(hostname -f)</h1>
      </body>
    </html>
    HTML
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${local.name_prefix}-asg-instance" })
  }

  tags = merge(var.tags, { Name = "${local.name_prefix}-app-lt" })
}

resource "aws_autoscaling_group" "private_asg" {
  name                      = "${local.name_prefix}-private-asg"
  min_size                  = 1
  max_size                  = 2
  desired_capacity          = 1
  health_check_type         = "ELB"
  health_check_grace_period = 300
  vpc_zone_identifier       = [aws_subnet.private[0].id, aws_subnet.private[1].id]
  target_group_arns         = [aws_lb_target_group.app_tg.arn]

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-private-asg-instance"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "cpu_scaling" {
  name                   = "${local.name_prefix}-cpu-scaling"
  autoscaling_group_name = aws_autoscaling_group.private_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}
