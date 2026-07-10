# Lab Manual

# Deploy a Python Application to an EC2 Instance using AWS CodeDeploy

**Lab Duration:** 90-120 Minutes

**Difficulty:** Intermediate

---

# Lab Objective

By the end of this lab, students will be able to:

* Understand AWS CodeDeploy architecture
* Configure an EC2 instance for CodeDeploy
* Install and configure the CodeDeploy Agent
* Create an IAM Role for EC2
* Create an IAM Role for CodeDeploy
* Create an Application in CodeDeploy
* Create a Deployment Group
* Upload application artifacts to S3
* Deploy a Python Flask application
* Verify successful deployment
* Troubleshoot deployment failures

---

# Architecture

```
Student Laptop
      │
      │
AWS CLI / Console
      │
      ▼
Amazon S3
      │
      ▼
AWS CodeDeploy
      │
      ▼
EC2 Instance
(CodeDeploy Agent)
      │
      ▼
Python Flask Application
```

---

# Lab Environment

| Resource         | Value             |
| ---------------- | ----------------- |
| OS               | Amazon Linux 2023 |
| Application      | Python Flask      |
| EC2 Name         | python-server     |
| Region           | us-east-1         |
| Deployment Type  | In-place          |
| Artifact Storage | Amazon S3         |

---

# Prerequisites

Already created

* EC2 Instance
* Python Installed
* SSM Enabled
* IAM Instance Profile Attached
* S3 Bucket
* AWS CLI Installed

---

# Lab-1

# Verify Existing Python Application

Login to the EC2 instance.

```
cd /home/ec2-user
```

Verify the application.

```
ls
```

Expected

```
app.py
requirements.txt
templates/
static/
```

Run the application.

```
python3 app.py
```

Open Browser

```
http://EC2-Public-IP:5000
```

Stop the application.

```
Ctrl + C
```

---

# Lab-2

# Install CodeDeploy Agent

Update packages.

```
sudo dnf update -y
```

Install Ruby.

```
sudo dnf install ruby wget -y
```

Go to temporary directory.

```
cd /tmp
```

Download installer.

For us-east-1

```
wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
```

Give execute permission.

```
chmod +x install
```

Install agent.

```
sudo ./install auto
```

Verify service.

```
sudo systemctl status codedeploy-agent
```

Expected

```
active (running)
```

Enable service.

```
sudo systemctl enable codedeploy-agent
```

---

# Lab-3

# Verify CodeDeploy Agent

Check service.

```
sudo service codedeploy-agent status
```

Expected

```
The AWS CodeDeploy agent is running
```

Check version.

```
sudo codedeploy-agent --version
```

View logs.

```
sudo tail -f /var/log/aws/codedeploy-agent/codedeploy-agent.log
```

Leave this terminal open.

---

# Lab-4

# Create Application Package

Create folder.

```
mkdir python-app
```

```
cd python-app
```

Copy application.

Example

```
app.py
requirements.txt
templates/
static/
```

Create appspec file.

```
vi appspec.yml
```

Paste

```yaml
version: 0.0

os: linux

files:
  - source: /
    destination: /home/ec2-user/python-app

hooks:

  BeforeInstall:
    - location: scripts/before_install.sh
      timeout: 300

  AfterInstall:
    - location: scripts/install_dependencies.sh
      timeout: 300

  ApplicationStart:
    - location: scripts/start_server.sh
      timeout: 300

  ValidateService:
    - location: scripts/validate.sh
      timeout: 300
```

Save.

---

# Lab-5

# Create Deployment Scripts

Create scripts folder.

```
mkdir scripts
```

---

## before_install.sh

```
vi scripts/before_install.sh
```

```bash
#!/bin/bash

pkill -f app.py || true

rm -rf /home/ec2-user/python-app
```

Permission

```
chmod +x scripts/before_install.sh
```

---

## install_dependencies.sh

```
vi scripts/install_dependencies.sh
```

```bash
#!/bin/bash

cd /home/ec2-user/python-app

python3 -m pip install -r requirements.txt
```

Permission

```
chmod +x scripts/install_dependencies.sh
```

---

## start_server.sh

```
vi scripts/start_server.sh
```

```bash
#!/bin/bash

cd /home/ec2-user/python-app

nohup python3 app.py > app.log 2>&1 &
```

Permission

```
chmod +x scripts/start_server.sh
```

---

## validate.sh

```
vi scripts/validate.sh
```

```bash
#!/bin/bash

sleep 10

curl http://localhost:5000

if [ $? -eq 0 ]
then
    echo "Application Running"
    exit 0
else
    echo "Application Failed"
    exit 1
fi
```

Permission

```
chmod +x scripts/validate.sh
```

---

# Lab-6

# Create Deployment Package

Go back.

```
cd ..
```

Create ZIP.

```
zip -r python-app.zip python-app
```

Verify.

```
unzip -l python-app.zip
```

Expected

```
appspec.yml
scripts/
app.py
requirements.txt
templates/
static/
```

---

# Lab-7

# Upload Package to S3

Open AWS Console.

Navigate

```
Amazon S3
```

Open Bucket.

```
training-codedeploy-bucket
```

Upload

```
python-app.zip
```

---

# Lab-8

# Create CodeDeploy Application

Open

```
AWS CodeDeploy
```

Click

```
Applications
```

Click

```
Create Application
```

Enter

Application Name

```
Python-Flask-App
```

Compute Platform

```
EC2/On-Premises
```

Click

```
Create Application
```

---

# Lab-9

# Create Deployment Group

Inside application

Click

```
Create Deployment Group
```

Deployment Group Name

```
python-group
```

Service Role

Select

```
CodeDeployServiceRole
```

Deployment Type

```
In-place
```

Environment

```
Amazon EC2 Instances
```

Tag

```
Name = python-server
```

Deployment Configuration

```
CodeDeployDefault.AllAtOnce
```

Load Balancer

```
Unchecked
```

Click

```
Create Deployment Group
```

---

# Lab-10

# Create Deployment

Inside Application

Click

```
Create Deployment
```

Revision Type

```
Amazon S3
```

Bucket

```
training-codedeploy-bucket
```

Object

```
python-app.zip
```

Deployment Group

```
python-group
```

Click

```
Create Deployment
```

---

# Lab-11

# Monitor Deployment

Deployment Lifecycle

```
Created

↓

Queued

↓

In Progress

↓

BeforeInstall

↓

AfterInstall

↓

ApplicationStart

↓

ValidateService

↓

Succeeded
```

---

# Lab-12

# Verify Application

Login EC2.

Check process.

```
ps -ef | grep python
```

Check application log.

```
tail -f /home/ec2-user/python-app/app.log
```

Verify.

```
curl http://localhost:5000
```

Browser

```
http://EC2-Public-IP:5000
```

Application should load successfully.

---

# Lab-13

# Verify Deployment Logs

Deployment logs

```
cd /opt/codedeploy-agent/deployment-root
```

Find latest deployment.

```
find . -name scripts.log
```

Open log.

```
cat scripts.log
```

Agent log.

```
sudo tail -100 /var/log/aws/codedeploy-agent/codedeploy-agent.log
```

---

# Lab-14

# Update the Application

Modify

```
app.py
```

Example

```python
return "Welcome to AWS CodeDeploy - Version 2"
```

Create package again.

```
zip -r python-app-v2.zip python-app
```

Upload to S3.

Create another deployment.

Observe

```
BeforeInstall

↓

AfterInstall

↓

ApplicationStart

↓

ValidateService
```

Refresh browser.

Updated application should appear.

---

# Troubleshooting Guide

| Issue                              | Possible Cause                         | Resolution                                            |
| ---------------------------------- | -------------------------------------- | ----------------------------------------------------- |
| Deployment failed in BeforeInstall | Script permissions missing             | `chmod +x scripts/*.sh`                               |
| ApplicationStart failed            | Wrong start command                    | Verify `start_server.sh`                              |
| ValidateService failed             | Application not listening on port 5000 | Check `app.py` and Security Group                     |
| CodeDeploy Agent Offline           | Agent stopped                          | `sudo systemctl restart codedeploy-agent`             |
| S3 Access Denied                   | Missing IAM permissions                | Add `AmazonS3ReadOnlyAccess` to the EC2 instance role |
| EC2 Not Found                      | Incorrect deployment group tags        | Verify EC2 tags match the deployment group            |
| Agent not registering              | Instance profile missing               | Attach an IAM role with CodeDeploy and S3 permissions |

---

# Learning Outcomes

After completing this lab, students will be able to:

* Install and configure the AWS CodeDeploy agent on an EC2 instance.
* Package a Python Flask application with an `appspec.yml` file and lifecycle hook scripts.
* Store deployment artifacts in Amazon S3.
* Create a CodeDeploy application and deployment group.
* Perform in-place deployments to an EC2 instance.
* Validate deployments using lifecycle hooks and log files.
* Troubleshoot common deployment failures using CodeDeploy agent logs and deployment logs.

This lab forms a strong foundation for CI/CD pipelines where services such as GitHub, Jenkins, or AWS CodePipeline automatically trigger CodeDeploy deployments after successful builds.
