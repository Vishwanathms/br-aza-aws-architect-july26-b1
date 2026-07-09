# Lab Manual: Collect Logs from an EC2 Instance and View Them in Amazon CloudWatch

## Lab Objective

By the end of this lab, you will be able to:

* Launch an EC2 instance
* Install the Amazon CloudWatch Agent
* Configure the CloudWatch Agent to collect application and system logs
* Send logs to Amazon CloudWatch Logs
* View and search logs in the CloudWatch console

---

# Lab Architecture

```text
                +----------------------+
                |    Amazon EC2        |
                |----------------------|
                | Amazon Linux 2023    |
                | CloudWatch Agent     |
                | Apache/Nginx Logs    |
                | System Logs          |
                +----------+-----------+
                           |
                           | HTTPS (443)
                           |
                    +------+------+
                    | CloudWatch  |
                    |    Logs     |
                    +-------------+
```

---

# Prerequisites

* AWS Account
* EC2 Instance (Amazon Linux 2023)
* Internet Connectivity
* IAM Role attached to EC2

---

# Required IAM Policy

Attach the following managed policy to the EC2 IAM Role.

```
CloudWatchAgentServerPolicy
```

---

# Step 1 – Launch EC2 Instance

Launch an Amazon Linux 2023 instance.

Example configuration

| Setting        | Value                     |
| -------------- | ------------------------- |
| AMI            | Amazon Linux 2023         |
| Instance Type  | t2.micro                  |
| Security Group | Allow SSH                 |
| IAM Role       | CloudWatchAgentServerRole |

Connect to the instance.

```bash
ssh -i key.pem ec2-user@<Public-IP>
```

---

# Step 2 – Install Apache (Generate Logs)

```bash
sudo dnf install httpd -y

sudo systemctl enable httpd

sudo systemctl start httpd
```

Verify

```bash
systemctl status httpd
```

---

Generate some web traffic.

```bash
curl localhost

curl localhost

curl localhost
```

Apache access log

```bash
sudo tail -f /var/log/httpd/access_log
```

---

# Step 3 – Install CloudWatch Agent

```bash
sudo dnf install amazon-cloudwatch-agent -y
```

Verify

```bash
rpm -qa | grep cloudwatch
```

---

# Step 4 – Create CloudWatch Agent Configuration

Create configuration file.

```bash
sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
```

```bash
sudo vi /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
```

Paste the following configuration.

```json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/ec2/system/messages",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/httpd/access_log",
            "log_group_name": "/ec2/apache/access",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/httpd/error_log",
            "log_group_name": "/ec2/apache/error",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
```

Save the file.

---

# Step 5 – Start CloudWatch Agent

```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
-a fetch-config \
-m ec2 \
-c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
-s
```

---

Check status.

```bash
sudo systemctl status amazon-cloudwatch-agent
```

---

# Step 6 – Verify Agent

```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status
```

Expected Output

```text
status: running
```

---

# Step 7 – Generate Test Logs -- Run on the EC2 instance

Generate Apache logs.

```bash
for i in {1..50}
do
curl localhost >/dev/null
done
```

Generate System Logs.

```bash
logger "CloudWatch Test Log Entry"
```

Check locally.

```bash
tail /var/log/messages
```

---

# Step 8 – Open CloudWatch Console

Navigate to

```
AWS Console
        ↓
CloudWatch
        ↓
Logs
        ↓
Log Groups
```

Expected Log Groups

```
/ec2/system/messages

/ec2/apache/access

/ec2/apache/error
```

---

# Step 9 – View Logs

Select

```
/ec2/apache/access
```

↓

Choose Log Stream

↓

View log entries.

Example

```
127.0.0.1 - - [09/Jul/2026:12:30:21] "GET / HTTP/1.1" 200
```

---

# Step 10 – Run CloudWatch Logs Insights

Navigate to

```
CloudWatch

↓

Logs Insights

↓

Select Log Group
```

Query

```sql
fields @timestamp, @message
| sort @timestamp desc
| limit 20
```

Run Query.

---

Example Filter

```sql
fields @timestamp,@message
| filter @message like /GET/
| sort @timestamp desc
```

---

# Step 11 – Create Metric Filter

Navigate

```
CloudWatch

↓

Log Groups

↓

Create Metric Filter
```

Pattern

```
404
```

Metric Namespace

```
Apache
```

Metric Name

```
404Errors
```

Save.

---

# Step 12 – Create Alarm

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
Apache/404Errors
```

Condition

```
Greater than 5
```

Notification

```
SNS Topic
```

Create Alarm.

---

# Validation

## Verify Agent

```bash
systemctl status amazon-cloudwatch-agent
```

---

Verify Service

```bash
sudo systemctl status httpd
```

---

Verify Logs

```bash
tail /var/log/httpd/access_log
```

---

Verify CloudWatch Agent

```bash
sudo journalctl -u amazon-cloudwatch-agent
```

---

# Troubleshooting

## Agent Not Starting

Check logs

```bash
sudo journalctl -u amazon-cloudwatch-agent
```

---

Validate Configuration

```bash
cat /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
```

---

Check IAM Role

```bash
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/
```

---

Restart Agent

```bash
sudo systemctl restart amazon-cloudwatch-agent
```

---

Verify Connectivity

```bash
ping logs.<region>.amazonaws.com
```

---

# Cleanup

1. Stop the CloudWatch Agent:

   ```bash
   sudo systemctl stop amazon-cloudwatch-agent
   ```
2. Delete the CloudWatch log groups.
3. Terminate the EC2 instance.
4. Remove the IAM role if it was created specifically for this lab.

---

# Expected Outcome

After completing this lab, you should be able to:

* Deploy and configure the Amazon CloudWatch Agent on an EC2 instance.
* Collect both system logs (`/var/log/messages`) and Apache web server logs (`access_log` and `error_log`).
* View, search, and analyze logs using Amazon CloudWatch Logs and Logs Insights.
* Create metric filters and CloudWatch alarms based on log events for proactive monitoring.
