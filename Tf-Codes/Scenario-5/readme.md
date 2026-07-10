# AWS CloudWatch Monitoring Lab using Systems Manager (SSM) and Terraform

## Lab Overview

In this lab, you will learn how to deploy and configure the Amazon CloudWatch Agent on Amazon EC2 instances using **AWS Systems Manager (SSM)** and **Terraform**, without requiring SSH access to the servers.

The lab environment consists of two Amazon EC2 instances:

* **Python Application Server** – Hosts a Python web application.
* **Redis Server** – Hosts a Redis database.

Both EC2 instances are already configured as **AWS Systems Manager Managed Instances**, allowing administrators to remotely install software, configure services, and execute commands through AWS Systems Manager.

Instead of manually installing the CloudWatch Agent on each server, you will automate the complete deployment using Terraform.

After completing this lab, CloudWatch will collect:

* System Metrics

  * CPU Utilization
  * Memory Utilization
  * Disk Utilization
  * Network Statistics
* System Logs
* Python Application Logs
* Redis Server Logs

---

# Learning Objectives

After completing this lab, you will be able to:

* Understand the architecture of CloudWatch monitoring.
* Verify AWS Systems Manager managed instances.
* Create CloudWatch Agent configuration files.
* Store configuration files in AWS Systems Manager Parameter Store.
* Install Amazon CloudWatch Agent remotely using Systems Manager.
* Configure the CloudWatch Agent through Systems Manager.
* Stream logs into Amazon CloudWatch Logs.
* View custom metrics in CloudWatch.
* Verify CloudWatch Agent operation.
* Automate monitoring deployment using Terraform.

---

# Architecture

```
                    +--------------------------------------+
                    |         Amazon CloudWatch            |
                    |--------------------------------------|
                    | Metrics                              |
                    | Logs                                 |
                    | Dashboards                           |
                    +------------------+-------------------+
                                       ^
                                       |
                          Amazon CloudWatch Agent
                                       ^
                                       |
                 +---------------------+----------------------+
                 |                                            |
        Amazon EC2 Instance                           Amazon EC2 Instance
        Python Application                            Redis Server
        (Managed by SSM)                              (Managed by SSM)

```

---

# Environment

| Resource         | Description                                                |
| ---------------- | ---------------------------------------------------------- |
| EC2 Instance 1   | Python Application Server                                  |
| EC2 Instance 2   | Redis Server                                               |
| Systems Manager  | Already Configured                                         |
| IAM Role         | AmazonSSMManagedInstanceCore + CloudWatchAgentServerPolicy |
| Terraform        | Installed on Local Machine                                 |
| AWS CLI          | Configured                                                 |
| CloudWatch Agent | Installed through SSM                                      |

---

# Prerequisites

Before starting the lab, verify the following:

* AWS CLI is installed.
* Terraform is installed.
* AWS credentials are configured.
* Both EC2 instances are running.
* Both EC2 instances are managed by Systems Manager.
* Instances have outbound Internet access or VPC endpoints for:

  * Systems Manager
  * CloudWatch
  * CloudWatch Logs
  * EC2 Messages
  * SSM Messages
* IAM Role is attached with:

  * AmazonSSMManagedInstanceCore
  * CloudWatchAgentServerPolicy

---

# Lab Directory Structure

```
cloudwatch-lab/

├── providers.tf
├── variables.tf
├── outputs.tf
├── main.tf
├── cloudwatch-config.json
└── README.md
```

---

# Step 1 – Verify Systems Manager Connectivity

Verify that the EC2 instances are registered with Systems Manager.

```bash
aws ssm describe-instance-information
```

Expected output should display both EC2 instances.

Example:

```
Python-Server

Redis-Server
```

If an instance does not appear, verify:

* IAM Role
* SSM Agent status
* Internet connectivity
* VPC endpoints (if applicable)

---

# Step 2 – Review CloudWatch Configuration

The file

```
cloudwatch-config.json
```

defines:

* Metrics to collect
* Log files to monitor
* CloudWatch Log Groups
* Metric Namespace

Metrics collected:

* CPU
* Memory
* Disk
* Network

Logs collected:

```
/var/log/messages

/var/log/python-app.log

/var/log/redis/redis-server.log
```

---

# Step 3 – Upload Configuration to Parameter Store

Terraform creates an SSM Parameter.

Example:

```
/cloudwatch/config
```

The CloudWatch Agent downloads this configuration during installation.

---

# Step 4 – Install CloudWatch Agent

Terraform creates an SSM Association using the AWS document:

```
AWS-ConfigureAWSPackage
```

The document automatically:

* Downloads the package
* Installs the agent
* Configures the service

No SSH connection is required.

---

# Step 5 – Configure the CloudWatch Agent

Terraform creates another Systems Manager Association.

AWS Document:

```
AmazonCloudWatch-ManageAgent
```

The document:

* Downloads configuration
* Applies configuration
* Starts the service
* Restarts if already running

---

# Step 6 – Initialize Terraform

Initialize the Terraform working directory.

```bash
terraform init
```

Expected output:

```
Terraform has been successfully initialized.
```

---

# Step 7 – Review the Execution Plan

Generate the execution plan.

```bash
terraform plan
```

Verify resources to be created.

Expected resources include:

* SSM Parameter
* SSM Associations

---

# Step 8 – Deploy Infrastructure

Deploy resources.

```bash
terraform apply
```

Type:

```
yes
```

Terraform creates:

* CloudWatch configuration
* Parameter Store entry
* Installation Association
* Configuration Association

---

# Step 9 – Verify Installation

Open the AWS Console.

Navigate to:

```
Systems Manager

↓

State Manager
```

Verify:

* Association Status
* Success

---

# Step 10 – Verify Agent Status

Open Systems Manager.

Run Command

Execute:

```
sudo systemctl status amazon-cloudwatch-agent
```

Expected:

```
Active: active (running)
```

Alternatively:

```
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
-m ec2 \
-a status
```

Expected:

```
running
```

---

# Step 11 – Verify CloudWatch Metrics

Open:

```
CloudWatch

↓

Metrics

↓

CWAgent
```

Verify the following metrics:

* CPU Usage
* Memory Usage
* Disk Usage
* Network Packets
* Network Bytes
* InstanceId

---

# Step 12 – Verify CloudWatch Logs

Navigate to:

```
CloudWatch

↓

Logs

↓

Log Groups
```

Expected Log Groups:

```
/application/system

/application/python

/application/redis
```

---

# Step 13 – Generate Application Activity

Generate requests against the Python application.

Example:

```
curl http://<PUBLIC-IP>:5000
```

Generate Redis traffic.

```
redis-cli

SET student aws

GET student

DEL student
```

Repeat multiple times.

---

# Step 14 – Observe Metrics

Return to CloudWatch.

Observe:

* CPU Increase
* Memory Changes
* Network Activity
* Log Streams
* Log Events

---

# CloudWatch Components Used

| Component          | Purpose                   |
| ------------------ | ------------------------- |
| CloudWatch Metrics | Performance monitoring    |
| CloudWatch Logs    | Centralized logging       |
| CloudWatch Agent   | Metric and log collection |
| Systems Manager    | Remote configuration      |
| Parameter Store    | Configuration storage     |
| Terraform          | Infrastructure automation |

---

# Terraform Resources Used

| Resource            | Purpose                         |
| ------------------- | ------------------------------- |
| aws_ssm_parameter   | Stores CloudWatch configuration |
| aws_ssm_association | Installs CloudWatch Agent       |
| aws_ssm_association | Configures CloudWatch Agent     |

---

# Validation Checklist

Verify the following before completing the lab:

* EC2 instances are managed by Systems Manager.
* Terraform completed successfully.
* CloudWatch Agent is running.
* Metrics are visible in CloudWatch.
* Python logs appear in CloudWatch Logs.
* Redis logs appear in CloudWatch Logs.
* System logs appear in CloudWatch Logs.
* CloudWatch namespace is visible.
* No failed Systems Manager associations exist.

---

# Troubleshooting

## EC2 Instance Not Appearing in Systems Manager

Possible causes:

* Incorrect IAM Role
* SSM Agent stopped
* No outbound Internet
* Missing VPC Endpoints

Check:

```bash
sudo systemctl status amazon-ssm-agent
```

---

## CloudWatch Agent Not Running

Check:

```bash
sudo systemctl status amazon-cloudwatch-agent
```

View logs:

```bash
sudo cat /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log
```

---

## No Metrics in CloudWatch

Verify:

* CloudWatch Agent is running.
* IAM permissions include `CloudWatchAgentServerPolicy`.
* Namespace matches the configuration.
* Wait 2–5 minutes for metrics to appear.

---

## Logs Not Appearing

Verify:

* Log file exists.
* File permissions allow the agent to read the file.
* Log path in `cloudwatch-config.json` is correct.
* Agent has been restarted after configuration changes.

---

# Cleanup

Remove all resources created during the lab.

```bash
terraform destroy
```

Type:

```
yes
```

Verify:

* SSM Associations removed.
* Parameter Store entry deleted.
* CloudWatch Agent configuration removed from Systems Manager.

---

# Summary

In this lab, you successfully automated the deployment of the Amazon CloudWatch Agent using AWS Systems Manager and Terraform. You installed and configured the agent remotely, collected system metrics and application logs from both the Python application server and the Redis server, and verified the data in Amazon CloudWatch without using SSH. This approach reflects a production-ready operations model where infrastructure is managed through Infrastructure as Code (IaC) and AWS Systems Manager, enabling secure, scalable, and repeatable deployments.
