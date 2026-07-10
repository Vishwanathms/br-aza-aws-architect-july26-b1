resource "aws_ssm_parameter" "cw_config" {

  name = "/cloudwatch/config"

  type = "String"

  value = file("${path.module}/cloudwatch-config.json")
}

resource "aws_ssm_association" "install_agent" {

  name = "AWS-ConfigureAWSPackage"

  targets {

    key = "InstanceIds"

    values = [
      var.python_instance_id,
      var.redis_instance_id
    ]
  }

  parameters = {

    action = "Install"

    name = "AmazonCloudWatchAgent"
  }
}

resource "aws_ssm_association" "configure_agent" {

  depends_on = [
    aws_ssm_association.install_agent
  ]

  name = "AmazonCloudWatch-ManageAgent"

  targets {

    key = "InstanceIds"

    values = [
      var.python_instance_id,
      var.redis_instance_id
    ]
  }

  parameters = {

    action = "configure"

    mode = "ec2"

    optionalConfigurationSource = "ssm"

    optionalConfigurationLocation = aws_ssm_parameter.cw_config.name

    optionalRestart = "yes"
  }
}