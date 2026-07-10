Below is a complete **AWS CloudWatch Monitoring Lab Manual** designed for students. The lab assumes:

* EC2-1 : Python Flask Application
* EC2-2 : Redis Server
* Both EC2 instances are already configured with **AWS Systems Manager (SSM)**
* Students will use **Run Command** instead of SSH wherever possible.
* Goal is to install CloudWatch Agent, deploy the configuration using SSM, and monitor application metrics and logs.

---

# Lab-08 : Monitoring Python Application using Amazon CloudWatch & AWS Systems Manager

## Lab Objective

In this lab you will learn how to

* Install CloudWatch Agent using Systems Manager
* Configure CloudWatch Agent
* Push configuration via Parameter Store
* Start CloudWatch Agent using SSM
* Monitor EC2 Metrics
* Monitor Memory and Disk Metrics
* Monitor Python Application Logs
* Create CloudWatch Dashboard
* Create CloudWatch Alarm

---

# Architecture

```
                   Internet

                      │
                      │
              Python Web Server
               Amazon EC2 Instance
             Port 5000 (Flask App)

                      │
                Redis Connection

                      │

               Redis EC2 Instance

                      │

          CloudWatch Agent (Both Servers)

                      │

             Amazon CloudWatch

          Metrics
          Logs
          Dashboard
          Alarms
```

---

# Lab Environment

| Server          | Purpose                   |
| --------------- | ------------------------- |
| EC2-1           | Python Flask Application  |
| EC2-2           | Redis Database            |
| Systems Manager | Execute Commands          |
| CloudWatch      | Monitoring                |
| Parameter Store | Store Agent Configuration |

---

# Task 1 Verify SSM

Open

```
AWS Console

↓

Systems Manager

↓

Managed Nodes
```

Both servers should display

```
Online
```

---

# Task 2 Create CloudWatch Log Group

Open

```
CloudWatch

↓

Log Groups

↓

Create Log Group
```

Create

```
python-app-logs
```

---

# Task 3 Install CloudWatch Agent using Systems Manager

Open

```
Systems Manager

↓

Run Command

↓

AWS-ConfigureAWSPackage
```

Choose

```
AmazonCloudWatchAgent
```

Action

```
Install
```

Targets

```
Python EC2

Redis EC2
```

Click

```
Run
```

Verify

```
Success
```

---

# Task 4 Verify Installation

Run Command

```
AWS-RunShellScript
```

Command

```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status
```

Initially

```
Stopped
```

is expected.

---

# Task 5 Create CloudWatch Configuration File

Create

```
cloudwatch-config.json
```

```json
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "metrics": {
    "append_dimensions": {
      "InstanceId": "${aws:InstanceId}"
    },
    "metrics_collected": {

      "mem": {
        "measurement": [
          "mem_used_percent"
        ]
      },

      "disk": {
        "measurement": [
          "used_percent"
        ],
        "resources": [
          "*"
        ]
      },

      "swap": {
        "measurement": [
          "swap_used_percent"
        ]
      }

    }
  },

  "logs": {

    "logs_collected": {

      "files": {

        "collect_list": [

          {
            "file_path": "/var/log/messages",
            "log_group_name": "python-app-logs",
            "log_stream_name": "{instance_id}"
          },

          {
            "file_path": "/opt/python/logs/app.log",
            "log_group_name": "python-app-logs",
            "log_stream_name": "{instance_id}-application"
          }

        ]
      }
    }
  }
}
```

---

# Task 6 Upload Configuration into Parameter Store

Open

```
Systems Manager

↓

Parameter Store

↓

Create Parameter
```

Name

```
AmazonCloudWatch-linux
```

Type

```
String
```

Paste the JSON.

Save.

---

# Task 7 Configure CloudWatch Agent using Run Command

Open

```
Systems Manager

↓

Run Command

↓

AmazonCloudWatch-ManageAgent
```

Operation

```
Configure
```

Mode

```
ec2
```

Optional Configuration Source

```
SSM Parameter Store
```

Parameter Name

```
AmazonCloudWatch-linux
```

Targets

```
Python EC2

Redis EC2
```

Run Command.

---

# Task 8 Verify Agent

Execute

```bash
sudo systemctl status amazon-cloudwatch-agent
```

or

```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status
```

Expected

```
running
```

---

# Task 9 Generate Application Traffic

Run

```bash
curl http://localhost:5000
```

or

```bash
while true
do
curl http://localhost:5000
sleep 1
done
```

Generate traffic for

```
5 minutes
```

---

# Task 10 Verify Metrics

Open

```
CloudWatch

↓

Metrics

↓

CWAgent
```

Observe

```
Memory Used %

Disk Used %

Swap Used %

CPU
```

---

# Task 11 Verify Logs

Open

```
CloudWatch

↓

Log Groups

↓

python-app-logs
```

Verify

```
Application Logs

System Logs
```

---

# Task 12 Create Dashboard

Open

```
CloudWatch

↓

Dashboards

↓

Create Dashboard
```

Dashboard Name

```
Python-App-Monitoring
```

Add Widgets

```
CPU Utilization

Memory %

Disk %

Network In

Network Out

Status Check Failed
```

---

# Task 13 Create CloudWatch Alarm

Navigate

```
CloudWatch

↓

Alarms

↓

Create Alarm
```

Metric

```
Memory Used %
```

Threshold

```
Greater than 80%
```

Evaluation

```
2 minutes
```

Notification

```
(Optional SNS)
```

---

# Task 14 Generate CPU Load

Execute

```bash
sudo yum install stress -y
```

Amazon Linux 2023

```bash
sudo dnf install stress -y
```

Run

```bash
stress --cpu 4 --timeout 300
```

Observe

```
CPU Utilization
```

in CloudWatch.

---

# Task 15 Generate Memory Load

Install

```bash
sudo dnf install stress-ng -y
```

Run

```bash
stress-ng --vm 2 --vm-bytes 1G --timeout 300s
```

Observe

```
Memory Used %
```

---

# Task 16 Generate Disk Usage

```bash
sudo fallocate -l 2G /tmp/testfile
```

or

```bash
dd if=/dev/zero of=/tmp/testfile bs=1M count=2048
```

Observe

```
Disk Used %
```

Delete

```bash
rm -f /tmp/testfile
```

---

# Task 17 Generate Application Logs

```bash
for i in {1..100}
do
echo "$(date) Student Test Log $i" >> /opt/python/logs/app.log
sleep 1
done
```

Verify logs in

```
CloudWatch Logs
```

---

# Validation Checklist

| Validation                 | Expected Result |
| -------------------------- | --------------- |
| SSM Agent Online           | ✅               |
| CloudWatch Agent Installed | ✅               |
| Configuration Applied      | ✅               |
| Agent Running              | ✅               |
| Memory Metrics Visible     | ✅               |
| Disk Metrics Visible       | ✅               |
| CPU Metrics Visible        | ✅               |
| Application Logs Visible   | ✅               |
| Dashboard Created          | ✅               |
| Alarm Created              | ✅               |

---

## Bonus Exercise (Optional)

Students can extend the monitoring solution by:

1. Collecting Redis logs (`/var/log/redis/redis.log`) into CloudWatch.
2. Installing the CloudWatch Agent on both the Python and Redis EC2 instances using the same SSM Parameter Store configuration.
3. Creating a CloudWatch dashboard that compares Python server and Redis server metrics side by side.
4. Creating an alarm to notify when Redis memory usage exceeds a defined threshold.
5. Using CloudWatch Logs Insights to search for application errors (for example, `ERROR` or `Exception`) in the Python application logs.

This lab gives students hands-on experience with a production-style monitoring setup using **AWS Systems Manager, CloudWatch Agent, CloudWatch Logs, Dashboards, and Alarms** without requiring SSH access to the instances.
