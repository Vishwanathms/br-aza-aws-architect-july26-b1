locals {
  name_prefix = var.vpc_name
}

# ===== AMI Data =====
data "aws_ami" "amazon_linux_3" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

# ===== SSH Key Pair =====
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

resource "local_file" "private_key" {
  count           = var.save_private_key ? 1 : 0
  filename        = var.private_key_path
  content         = tls_private_key.key.private_key_pem
  file_permission = "0600"
}

# ===== IAM Role for SSM =====
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

# ===== Security Groups =====
resource "aws_security_group" "alb_sg" {
  name   = "${local.name_prefix}-alb-sg"
  vpc_id = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.name_prefix}-alb-sg" })
}

resource "aws_security_group" "nginx_sg" {
  name   = "${local.name_prefix}-nginx-sg"
  vpc_id = var.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.name_prefix}-nginx-sg" })
}

resource "aws_security_group" "python_sg" {
  name   = "${local.name_prefix}-python-sg"
  vpc_id = var.vpc_id

  ingress {
    description     = "Python app port from Nginx"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.nginx_sg.id]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.name_prefix}-python-sg" })
}

resource "aws_security_group" "redis_sg" {
  name   = "${local.name_prefix}-redis-sg"
  vpc_id = var.vpc_id

  ingress {
    description     = "Redis port from Python"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.python_sg.id]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.name_prefix}-redis-sg" })
}

# ===== ALB and Target Group =====
resource "aws_lb" "app_alb" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids

  tags = merge(var.tags, { Name = "${local.name_prefix}-alb" })
}

resource "aws_lb_target_group" "nginx_tg" {
  name     = "${local.name_prefix}-nginx-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = merge(var.tags, { Name = "${local.name_prefix}-nginx-tg" })
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_tg.arn
  }
}

# ===== Nginx Launch Template and ASG =====
resource "aws_launch_template" "nginx_lt" {
  name_prefix   = "${local.name_prefix}-nginx-lt-"
  image_id      = data.aws_ami.amazon_linux_3.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.generated.key_name

  vpc_security_group_ids = [aws_security_group.nginx_sg.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ssm_profile.name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    dnf update -y
    dnf install -y amazon-ssm-agent nginx

    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent

    systemctl enable nginx
    systemctl start nginx

    # Get Python app IP (will be passed as an environment variable)
    PYTHON_APP_IP="${aws_instance.python_app.private_ip}"

    # Configure nginx to reverse proxy to Python app
    cat > /etc/nginx/conf.d/proxy.conf <<'NGINX'
    server {
        listen 80 default_server;
        server_name _;

        location / {
            proxy_pass http://$${PYTHON_APP_IP}:5000;
            proxy_set_header Host \$$host;
            proxy_set_header X-Real-IP \$$remote_addr;
            proxy_set_header X-Forwarded-For \$$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$$scheme;
        }
    }
    NGINX

    # Replace placeholder with actual IP
    sed -i "s/\$${PYTHON_APP_IP}/${aws_instance.python_app.private_ip}/g" /etc/nginx/conf.d/proxy.conf

    systemctl reload nginx
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${local.name_prefix}-nginx-instance" })
  }

  tags = merge(var.tags, { Name = "${local.name_prefix}-nginx-lt" })
}

resource "aws_autoscaling_group" "nginx_asg" {
  name                      = "${local.name_prefix}-nginx-asg"
  min_size                  = 1
  max_size                  = 3
  desired_capacity          = 1
  health_check_type         = "ELB"
  health_check_grace_period = 300
  vpc_zone_identifier       = var.private_subnet_ids
  target_group_arns         = [aws_lb_target_group.nginx_tg.arn]

  launch_template {
    id      = aws_launch_template.nginx_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-nginx-asg-instance"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "nginx_cpu_scaling" {
  name                   = "${local.name_prefix}-nginx-cpu-scaling"
  autoscaling_group_name = aws_autoscaling_group.nginx_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# ===== Python Application EC2 =====
resource "aws_instance" "python_app" {
  ami                    = data.aws_ami.amazon_linux_3.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.python_sg.id]
  key_name               = aws_key_pair.generated.key_name
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

  user_data_base64 = base64encode(<<-EOF
    #!/bin/bash
    set -e
    dnf update -y
    dnf install -y amazon-ssm-agent python3 python3-pip

    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent

    # Install Python dependencies
    pip3 install flask redis

    # Get Redis IP
    REDIS_IP="${aws_instance.redis_db.private_ip}"

    # Create Python Flask app
    cat > /opt/app.py <<'PYTHON'
from flask import Flask, jsonify
import redis
import os

app = Flask(__name__)

# Connect to Redis
redis_host = os.environ.get('REDIS_IP', 'localhost')
redis_client = redis.Redis(host=redis_host, port=6379, decode_responses=True)

@app.route('/')
def home():
    try:
        redis_client.ping()
        return jsonify({
            "status": "ok",
            "message": "Connected to Redis",
            "hostname": os.popen('hostname').read().strip()
        })
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/health')
def health():
    return jsonify({"status": "healthy"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
    PYTHON

    # Set Redis IP environment variable and start Flask app
    export REDIS_IP=$REDIS_IP
    nohup python3 /opt/app.py > /var/log/flask_app.log 2>&1 &
  EOF
  )

  tags = merge(var.tags, { Name = "${local.name_prefix}-python-app" })
}

# ===== Redis Database EC2 =====
resource "aws_instance" "redis_db" {
  ami                    = data.aws_ami.amazon_linux_3.id
  instance_type          = var.instance_type
  subnet_id              = var.db_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.redis_sg.id]
  key_name               = aws_key_pair.generated.key_name
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

  user_data_base64 = base64encode(<<-EOF
    #!/bin/bash
    set -e
    dnf update -y
    dnf install -y amazon-ssm-agent redis

    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent

    systemctl enable redis
    systemctl start redis

    # Configure Redis to listen on all interfaces
    sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf
    systemctl restart redis
  EOF
  )

  tags = merge(var.tags, { Name = "${local.name_prefix}-redis-db" })
}
