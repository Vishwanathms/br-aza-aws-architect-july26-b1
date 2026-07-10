# Manual Setup Guide - 3-Tier Application

This guide provides step-by-step instructions to manually set up the Python Flask application, Redis database, and Nginx reverse proxy on your EC2 instances.

## Prerequisites

- Terraform has been applied successfully and all EC2 instances are running
- You have the SSH private key file locally
- You have AWS CLI configured or access to the AWS console to retrieve instance details

## Step 1: Retrieve Instance Details

### Get Instance Information

```bash
# From your terraform directory, get the instance details
cd /home/obcot/Documents/repos/TF-Codes/Scenario-4

# Get Python App Instance Private IP
terraform output -json | grep python_app_ip

# Get Redis Instance Private IP
terraform output -json | grep redis_db_ip

# Get Nginx ASG Instance Private IP
terraform output -json | grep nginx

# Alternatively, check your AWS console:
# - EC2 Dashboard > Instances
# - Find instances with names like "my-vpc-python-app", "my-vpc-redis-db", "my-vpc-nginx-asg-instance"
# - Note their private IPs
```

**Save these IPs for reference:**
- Python App Private IP: `10.0.x.x` (in private-app subnet)
- Redis DB Private IP: `10.0.x.x` (in database subnet)
- Nginx Instance Private IP: `10.0.x.x` (in private-app subnet)

---

## Step 2: Set Up Redis Database

### Connect to Redis Instance via AWS Systems Manager

```bash
# Get your AWS region from terraform.tfvars or your state file
# Example: us-east-1

# Connect via SSM (requires IAM role with SSM permissions - already attached by Terraform)
aws ssm start-session --target i-<REDIS_INSTANCE_ID> --region us-east-1
```

**Once connected to the Redis instance:**

```bash
# Update and install Redis
sudo dnf update -y
sudo dnf install -y redis6

# Start Redis service
sudo systemctl start redis6
sudo systemctl enable redis6

# Configure Redis to listen on all interfaces
sudo sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis6/redis6.conf
sudo sed -i 's/^# protected-mode yes/protected-mode no/' /etc/redis6/redis6.conf

# Restart Redis
sudo systemctl restart redis6

# Verify Redis is running and listening on port 6379
redis6-cli ping
# Expected output: PONG
```

**Exit the session:**
```bash
exit
```

---

## Step 3: Set Up Python Flask Application

### Connect to Python App Instance

```bash
# Connect via SSM
aws ssm start-session --target i-<PYTHON_APP_INSTANCE_ID> --region us-east-1
```

**Once connected to the Python app instance:**

### 3.1 Install Python and Dependencies

```bash
# Update system packages
sudo dnf update -y

# Install Python 3 and pip
sudo dnf install -y python3 python3-pip

# Upgrade pip
sudo python3 -m pip install --upgrade pip

# Install Flask and Redis client library
sudo python3 -m pip install flask redis
```

### 3.2 Create the Flask Application

```bash
# Create app directory
sudo mkdir -p /opt

# Create the Flask app file
sudo tee /opt/app.py > /dev/null <<'EOF'
from flask import Flask, jsonify
import os
import redis

app = Flask(__name__)

# Get Redis IP from environment variable (will be set below)
redis_host = os.environ.get('REDIS_IP', '10.0.4.128')  # Replace with your Redis private IP
redis_client = redis.Redis(host=redis_host, port=6379, decode_responses=True)

@app.route('/')
def home():
    try:
        redis_client.ping()
        return jsonify({
            'status': 'ok',
            'message': 'Connected to Redis',
            'hostname': os.popen('hostname').read().strip()
        })
    except Exception as exc:
        return jsonify({'status': 'error', 'message': str(exc)}), 500

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF
```

**IMPORTANT:** Edit the Redis IP in the file:
```bash
# Replace with your actual Redis private IP
sudo sed -i "s/10.0.4.128/<YOUR_REDIS_PRIVATE_IP>/g" /opt/app.py

# Example:
sudo sed -i "s/10.0.4.128/10.0.4.150/g" /opt/app.py
```

### 3.3 Create a Systemd Service for Flask App

```bash
# Create systemd service file
sudo tee /etc/systemd/system/flask-app.service > /dev/null <<'EOF'
[Unit]
Description=Flask application
After=network-online.target

[Service]
Environment=REDIS_IP=10.0.4.128
WorkingDirectory=/opt
ExecStart=/usr/bin/python3 /opt/app.py
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
```

**IMPORTANT:** Edit the Redis IP in the service file:
```bash
# Replace with your actual Redis private IP
sudo sed -i "s/10.0.4.128/<YOUR_REDIS_PRIVATE_IP>/g" /etc/systemd/system/flask-app.service

# Example:
sudo sed -i "s/10.0.4.128/10.0.4.150/g" /etc/systemd/system/flask-app.service
```

### 3.4 Start the Flask Application

```bash
# Reload systemd daemon
sudo systemctl daemon-reload

# Enable service to start on boot
sudo systemctl enable flask-app

# Start the Flask application
sudo systemctl start flask-app

# Check status
sudo systemctl status flask-app

# View logs
sudo journalctl -u flask-app -f
```

### 3.5 Verify Flask App is Running

```bash
# Test the health endpoint
curl http://127.0.0.1:5000/health

# Expected output:
# {"status":"healthy"}

# Test the home endpoint
curl http://127.0.0.1:5000/

# Expected output (if Redis is connected):
# {"status":"ok","message":"Connected to Redis","hostname":"..."}
```

**Exit the session:**
```bash
exit
```

---

## Step 4: Configure Nginx Reverse Proxy

### Connect to Nginx Instance

```bash
# Connect via SSM
aws ssm start-session --target i-<NGINX_INSTANCE_ID> --region us-east-1
```

**Once connected to the Nginx instance:**

### 4.1 Configure Nginx as Reverse Proxy

```bash
# Create Nginx proxy configuration
sudo tee /etc/nginx/conf.d/proxy.conf > /dev/null <<'EOF'
server {
    listen 80 default_server;
    server_name _;

    location / {
        proxy_pass http://10.0.2.100:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }

    # Health check endpoint for load balancer
    location /nginx-health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF
```

**IMPORTANT:** Replace the Python app IP:
```bash
# Replace 10.0.2.100 with your actual Python app private IP
sudo sed -i "s/10.0.2.100/<YOUR_PYTHON_APP_IP>/g" /etc/nginx/conf.d/proxy.conf

# Example:
sudo sed -i "s/10.0.2.100/10.0.2.85/g" /etc/nginx/conf.d/proxy.conf
```

### 4.2 Test Nginx Configuration

```bash
# Test configuration syntax
sudo nginx -t

# Expected output:
# nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
# nginx: configuration file /etc/nginx/nginx.conf test is successful
```

### 4.3 Reload Nginx

```bash
# Reload Nginx to apply configuration
sudo systemctl reload nginx

# Verify Nginx status
sudo systemctl status nginx
```

### 4.4 Test Nginx Reverse Proxy

```bash
# Test the health endpoint through Nginx
curl http://127.0.0.1:80/nginx-health

# Expected output:
# healthy

# Test the app through Nginx
curl http://127.0.0.1:80/

# Expected output (should proxy to Python app):
# {"status":"ok","message":"Connected to Redis","hostname":"..."}
```

**Exit the session:**
```bash
exit
```

---

## Step 5: Test End-to-End Connection

### Access from Your Local Machine

```bash
# Get the ALB DNS name
aws elbv2 describe-load-balancers --query 'LoadBalancers[0].DNSName' --region us-east-1

# Or retrieve from Terraform
terraform output -json | grep alb_dns

# Test through ALB (from your local machine)
curl http://<ALB_DNS_NAME>/

# Expected output:
# {"status":"ok","message":"Connected to Redis","hostname":"..."}
```

---

## Step 6: Troubleshooting

### Redis Connection Issues

```bash
# SSH to Python app instance and check Redis connectivity
redis-cli -h <REDIS_PRIVATE_IP> -p 6379 ping

# Check Flask app logs
sudo journalctl -u flask-app -f
```

### Nginx Reverse Proxy Issues

```bash
# SSH to Nginx instance and check configuration
sudo nginx -t

# Check Nginx error logs
sudo tail -f /var/log/nginx/error.log

# Check access logs
sudo tail -f /var/log/nginx/access.log
```

### Security Group Issues

- Verify **Python SG** allows port 5000 from **Nginx SG**
- Verify **Redis SG** allows port 6379 from **Python SG**
- Verify **Nginx SG** allows port 80 from **ALB SG**

```bash
# From AWS CLI
aws ec2 describe-security-groups --filters Name=group-name,Values=my-vpc-python-sg --region us-east-1
aws ec2 describe-security-groups --filters Name=group-name,Values=my-vpc-redis-sg --region us-east-1
aws ec2 describe-security-groups --filters Name=group-name,Values=my-vpc-nginx-sg --region us-east-1
```

### Port Connectivity Test

```bash
# From Nginx instance, test connection to Python app on port 5000
telnet <PYTHON_APP_IP> 5000

# From Python instance, test connection to Redis on port 6379
telnet <REDIS_IP> 6379
```

---

## Quick Reference - Command Summary

### Redis Setup (One Liner)
```bash
sudo dnf update -y && sudo dnf install -y redis && \
sudo sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf && \
sudo sed -i 's/^# protected-mode yes/protected-mode no/' /etc/redis/redis.conf && \
sudo systemctl enable redis && sudo systemctl start redis
```

### Python App Setup (One Liner)
```bash
sudo dnf update -y && sudo dnf install -y python3 python3-pip && \
sudo python3 -m pip install flask redis && \
sudo mkdir -p /opt
# Then follow Section 3.2 to create app.py and service file
```

### Nginx Setup (One Liner)
```bash
sudo dnf update -y && sudo dnf install -y nginx && \
sudo systemctl enable nginx && sudo systemctl start nginx
# Then follow Section 4.1 to create proxy configuration
```

---

## File Locations Summary

| Component | Key File | Location |
|-----------|----------|----------|
| Flask App | app.py | `/opt/app.py` |
| Flask Service | flask-app.service | `/etc/systemd/system/flask-app.service` |
| Nginx Config | proxy.conf | `/etc/nginx/conf.d/proxy.conf` |
| Redis Config | redis.conf | `/etc/redis/redis.conf` |
| Flask Logs | Journal logs | `sudo journalctl -u flask-app -f` |
| Nginx Access Logs | access.log | `/var/log/nginx/access.log` |
| Nginx Error Logs | error.log | `/var/log/nginx/error.log` |

