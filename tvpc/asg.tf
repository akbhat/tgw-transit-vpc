#provider "aws" {
#  region = "us-east-1"
#}

#data "aws_availability_zones" "available" {}

#resource "aws_vpc" "tvpc" {
#  cidr_block = "10.10.0.0/16"
#  enable_dns_hostnames = true
#
#  tags = {
#    Name = "Transit VPC"
#  }
#}

#data "aws_ami" "vsrx3_ami" {
#  most_recent = true
#  owners      = ["679593333241", "298183613488"]
#
#  filter {
#    name = "name"
#
##    values = ["*srx*18.4R1.8--pm*"]
#    values = ["*srx*19.1R1.6-std*"]
#  }
#}

#resource "aws_key_pair" "deployer" {
#  key_name   = "deployer-key"
#  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDW3fBHRMTQ3CUxWUnYD2XmjNjO8J6T038rYqjzUCNTYbWWCbH9sfdBu/GJpnh207hEB+PzRpKJnhsvPogb/wNNi0KzarWoUPKtqt0VQkpZg4fsIUcscyFiR3cb9pzKR4UOJzQo7ZTO0ulKqFeyrmDHM89bFMcC6ATz5lIvO5ZNukdtZ1+gnKqTLMoq8VcPYIllnOFNTiEpQyr+COmLMjNN7CVRqCmAo0vIw2mNZpA2hk/Nmstv7gxEGch2VNdJw6nOIaO9XXX+DcJagPoyJsjeuVb0yKi/DmEgPTZXhAsZ9Sgv8/pdj0vDf3O/G2LelohJ315q1p5h4pL2HGbVrnbf akbhat@ubuntu"
#}

data "template_file" "vsrx-conf" {
  template = "${file("vsrx-init.tpl")}"

  vars {
    SshPublicKey = "${trimspace("${file(var.public_key_path)}")}"
    LambdaSshPublicKey  = "${var.primary_region ? format("%s %s", "ssh-rsa",aws_cloudformation_stack.lambdas.outputs["VSRXPUBKEY"]) : "ssh-rsa SAFETODELETE"}"
  }
}

resource "aws_launch_template" "tvpc_vsrx" {
  name_prefix   = "vsrx"
  image_id      = "${data.aws_ami.vsrx3_ami.id}"
  instance_type = "c4.xlarge"

#  key_name      = "${aws_key_pair.deployer.key_name}"
  ebs_optimized           = true
  disable_api_termination = false
  user_data               = "${base64encode(data.template_file.vsrx-conf.rendered)}"

  network_interfaces {
    device_index                = 0
    security_groups             = ["${aws_security_group.VSRXSecurityGroup.id}"]
    associate_public_ip_address = true
    delete_on_termination       = true
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "Transit VPC VSRX"
  }
}

#resource "aws_internet_gateway" "igw" {
#  vpc_id = "${aws_vpc.tvpc.id}"
#
#  tags = {
#    Name = "Transit VPC IGW"
#  }
#}

#resource "aws_route_table" "VPCRouteTable" {
#  vpc_id = "${aws_vpc.tvpc.id}"
#
#  route {
#    cidr_block = "0.0.0.0/0"
#    gateway_id = "${aws_internet_gateway.igw.id}"
#  }
#
#  tags = {
#    Name = "Transit VPC"
#  }
#}

#resource "aws_route_table_association" "VPCPubSubnetRouteTableAssociation1" {
#  subnet_id      = "${aws_subnet.VPCPubSub11.id}"
#  route_table_id = "${aws_route_table.VPCRouteTable.id}"
#}

#resource "aws_route_table_association" "VPCPubSubnetRouteTableAssociation2" {
#  subnet_id      = "${aws_subnet.VPCPubSub21.id}"
#  route_table_id = "${aws_route_table.VPCRouteTable.id}"
#}

#resource "aws_subnet" "VPCPubSub11" {
#  vpc_id            = "${aws_vpc.tvpc.id}"
#  cidr_block        = "10.10.10.0/24"
#  availability_zone = "${data.aws_availability_zones.available.names[0]}"
#}

#resource "aws_subnet" "VPCPubSub21" {
#  vpc_id            = "${aws_vpc.tvpc.id}"
#  cidr_block        = "10.10.20.0/24"
#  availability_zone = "${data.aws_availability_zones.available.names[1]}"
#}

#resource "aws_subnet" "VPCPubSub12" {
#  vpc_id            = "${aws_vpc.tvpc.id}"
#  cidr_block        = "10.10.30.0/24"
#  availability_zone = "${data.aws_availability_zones.available.names[0]}"
#
#  tags = {
#    "Name"      = "vSRX1 Data Subnet"
#    "eni:index" = "1"
#  }
#}

#resource "aws_subnet" "VPCPubSub22" {
#  vpc_id            = "${aws_vpc.tvpc.id}"
#  cidr_block        = "10.10.40.0/24"
#  availability_zone = "${data.aws_availability_zones.available.names[1]}"
#
#  tags = {
#    "Name"      = "vSRX2 Data Subnet"
#    "eni:index" = "1"
#  }
#}

resource "aws_autoscaling_group" "tvpc_vsrx" {
  name                      = "${aws_launch_template.tvpc_vsrx.name}-asg"
  max_size                  = 5
  min_size                  = 2
  health_check_grace_period = 900
  health_check_type         = "EC2"
  desired_capacity          = 2
  force_delete              = true
  vpc_zone_identifier       = ["${aws_subnet.VPCPubSub11.id}", "${aws_subnet.VPCPubSub21.id}"]
  wait_for_capacity_timeout = 0

  launch_template {
    id      = "${aws_launch_template.tvpc_vsrx.id}"
    version = "$$Latest"
  }

  initial_lifecycle_hook {
    name                 = "eni-attach"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 2000
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"

    notification_metadata = <<EOF
{${aws_vpc.tvpc.id}:${aws_security_group.VSRXSecurityGroup.id}}
EOF
  }

  initial_lifecycle_hook {
    name                 = "eni-detach"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 2000
    lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
  }

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "vSRX_ASG"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "vsrx_scaling" {
  name                      = "vsrx-scaling-policy"
  adjustment_type           = "ChangeInCapacity"
  estimated_instance_warmup = 600
  autoscaling_group_name    = "${aws_autoscaling_group.tvpc_vsrx.name}"

  policy_type = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"

      #      predefined_metric_type = "ASGAverageNetworkIn"
    }

    target_value = "60"
  }
}

data "aws_iam_policy_document" "instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "asg_add_eni_role" {
  #  count= "${var.enable_auto_scaling}"
  name               = "asg_add_eni_role"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.instance-assume-role-policy.json}"
}

resource "aws_iam_role_policy" "asg_add_eni_policy" {
  #  count= "${var.enable_auto_scaling}"
  name = "asg_add_eni_policy"
  role = "${aws_iam_role.asg_add_eni_role.id}"

  policy = <<EOF
{
       "Statement": [
           {
               "Action": [
                   "logs:CreateLogGroup",
                   "logs:CreateLogStream",
                   "logs:PutLogEvents"
               ],
               "Effect": "Allow",
               "Resource": "arn:aws:logs:*:*:*"
           },
           {
               "Action": [
                   "ec2:CreateNetworkInterface",
                   "ec2:DescribeNetworkInterfaces",
                   "ec2:DetachNetworkInterface",
                   "ec2:DeleteNetworkInterface",
                   "ec2:AttachNetworkInterface",
                   "ec2:DescribeInstances",
                   "ec2:DescribeSubnets",
		   "ec2:ModifyNetworkInterfaceAttribute",
                   "ec2:DescribeVpnConnections",
                   "ec2:DescribeCustomerGateways",
                   "ec2:DeleteCustomerGateway",
                   "ec2:DeleteVpnConnection",
                   "ec2:DescribeAddresses",
                   "ec2:DisassociateAddress",
                   "ec2:ReleaseAddress",
                   "autoscaling:CompleteLifecycleAction",
                   "cloudwatch:PutMetricAlarm",
		   "sns:ListTopics",
                   "cloudwatch:DeleteAlarms"
               ],
               "Effect": "Allow",
               "Resource": "*"
           }
       ],
       "Version": "2012-10-17"
}
  EOF
}

#When a Lambda function is configured to run within a VPC, it incurs an
#additional ENI start-up penalty. For attach_eni this means further delay 
#in vSRX coming up. Hopefully 900 seconds is sufficient.
resource "aws_lambda_function" "asg_attach_eni" {
# count            = "${var.enable_auto_scaling}"
  function_name = "asg_attach_eni"
  role          = "${aws_iam_role.asg_add_eni_role.arn}"
  handler       = "attach_eni.lambda_handler"
  timeout       = 300

#  source_code_hash = "${base64sha256(file("attach_eni.py"))}"
  runtime   = "python2.7"
  s3_bucket = "akbhat-transit-gw-solution"
  s3_key    = "attach_eni.zip"
}

resource "aws_cloudwatch_event_rule" "vsrx_autoscaling" {
  name        = "vsrx_auto_scaling"
  description = "vSRX AutoScaling"

  event_pattern = <<PATTERN
{
    "source": [
        "aws.autoscaling"
    ],
    "detail-type": [
        "EC2 Instance-launch Lifecycle Action",
        "EC2 Instance-terminate Lifecycle Action"
    ],
    "detail": {
        "AutoScalingGroupName": ["${aws_autoscaling_group.tvpc_vsrx.name}"]
    }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "asg_scaling_lambda" {
  #  count     = "${var.enable_auto_scaling}"
  rule      = "${aws_cloudwatch_event_rule.vsrx_autoscaling.name}"
  target_id = "Trigger_Attach_ENI_Lambda"
  arn       = "${aws_lambda_function.asg_attach_eni.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.asg_attach_eni.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.vsrx_autoscaling.arn}"
}
