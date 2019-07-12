#resource "aws_ec2_transit_gateway" "tvpc_tgw" {
#  description = "TVPC TGW"
#  default_route_table_association = "disable"
#  default_route_table_propagation = "disable"
#  tags = {
#    "transitvpc:spoke" = "false"
#  }
#}

resource "aws_sns_topic" "instance_check_updates" {
  name = "instance-check-updates"
}

resource "aws_sns_topic_subscription" "instance_check_updates_trigger_lambda" {
  topic_arn = "${aws_sns_topic.instance_check_updates.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.configure_tgw_vpn_tunnels.arn}"
}

resource "aws_lambda_layer_version" "pyez" {
  s3_bucket  = "akbhat-transit-gw-solution"
  s3_key     = "pyez_layer.zip"
  layer_name = "pyez"

  compatible_runtimes = ["python3.7"]
}

resource "aws_lambda_layer_version" "boto3" {
  s3_bucket  = "akbhat-transit-gw-solution"
  s3_key     = "boto3.zip"
  layer_name = "boto3"

  compatible_runtimes = ["python3.7"]
}

resource "aws_lambda_function" "configure_tgw_vpn_tunnels" {
  function_name = "tgw_vpn_config"
  role          = "${aws_iam_role.tgw_vpn_role.arn}"
  handler       = "tgw_vpn_config.lambda_handler"
  timeout       = 300
  runtime       = "python3.7"
  s3_bucket     = "akbhat-transit-gw-solution"
  s3_key        = "tgw_vpn_config.zip"
  layers = ["${aws_lambda_layer_version.pyez.arn}", "${aws_lambda_layer_version.boto3.arn}"]
#  vpc_config  {
#    subnet_ids = ["${aws_subnet.VPCPubSub11.id}", "${aws_subnet.VPCPubSub21.id}"]
#    security_group_ids = ["${aws_security_group.JuniperConfigSecurityGroup.id}"]
#  }

#TODO: https://docs.aws.amazon.com/lambda/latest/dg/tutorial-env_console.html
# How to encrypt an env variable containing sensitive information
  environment {
    variables = {
#      pri_ssh_key  = "${local_file.vsrx_priv_ssh_key.content}" 
      cgw_asn      = "64513"
      tgw          = "${aws_ec2_transit_gateway.tvpc_tgw.id}" 
      pri_ssh_key = <<EOF
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEA1t3wR0TE0NwlMVlJ2A9l5ozYzvCek9N/K2Ko81AjU2G1lgmx
/bH3QbvxiaZ4dtO4RAfj80aSiZ4bLz6IG/8DTYtCs2q1qFDyrardFUJKWYOH7CFH
LHMhYkd3G/acykeFDic0KO2UztLpSqhXsq5gxzPPWxTHAugE8+ZSLzuWTbpHbWdf
oJyqkyzKKvFXD2CJZZzhTU4hKUMq/gjpizIzTewlUagpgKNLyMNpjWaQNoZPzZrL
b+4MRBnIdlTXScOpziGjvV11/g3CWoD6MibI3rlW9Miovw5hID02V4QLGfUoL/P6
XY9Lw39zvxti3paISd9eataeYeKS9hxm1a523wIDAQABAoIBAQDH25JmyCmF2G9j
8piENvZit3nnKttlxyEPmuppv43MPiNoVsZPotzJMOcfUU/Vv2MzLF+0Zl1hUkYY
8MIrwE0zMKivOD+WOw0vyrFv18ROdNDWK7IHP2O7BZxdz0rRwCqcGo0i0LJMmtPS
1LkWA6sTPzbNkor2QhhxQTgKpRNOYZR+Yif7+CbhNe/j8V1qityTIGOXGzEXadOT
tFm/bzOYgmbEM0IMHX8nZ3/YFBxOBW5ehBTZ6ViU2OoA6+TEVXyaNz2gzubzHyOp
SEgY9gxm9m1ktOxR2PDe7Iyf9aoIcEkzcxdb33qrg4GlC53ss38NVsBrkeR6sr2J
D9ly31NRAoGBAPj7lhbIp993T7hhC+hKC5g+/2nLPoOIc4dyOyg89mQVIkR5G6Np
skZaASNduox1FbjVh5ONo6nA4vkEOP/WjEfsdPNZFC4lc2qWEU5HvX5OHY25RZyT
oQbqpK8HlPHMAPemRKaGLuN/pIYU3KzSNnobY4N5LeEh+2hsuP4G8WtJAoGBANzs
NM/r38RUShXEIRGkYp1++C6vlcCmWtZEFqLjowaV7ACtCHwhhJIxgXuI6IHq8v8c
C+WefgdbP8kPFX0vIdwl99yMu+mULv2lxXmbul/huCCWLK36oa4Ms/3EQpgeId+u
UPbtMrbGi1Rd40QkjNtvWuCTAAbNWeJVscvDOWjnAoGAOUCw7KBLaelnnYBDWrDc
JbAmz077GwffeP/ddo0+Ixlw/cnTfyoo4mCD7nv5D59E1XHUcSuavMgr6RL9gGb3
bvqCkgqjx1C5T4Mei5+XhVm1FgfKaAzSdGK0Z8MYjtlYR5omIxyr34hUbriRXfQg
rsdphKvyztgflY2apF84WHECgYEAzxW7C4uW3XoFWBHYzajBp9B0445DWaqWS3LX
pSiskGfIKXoJEhJ5KnCtZxcWm3GZBflMTZkbmdm3GMjC4+1iV/JfPKXPH0yAH9Nc
IHoRYf87kZAzoYHmPDg8IAvwQJc+OWY1DsGZYCsMP7Eib6WzQ55GGWyyAa5MKxUY
7F+7WNECgYEA6ad+V8XSnEBJ6cA96qePI0CRwFQ2yUhmCijk/VaCKsaVCz12KLNE
5SzCP2nQQF/GmlAyYyUwa59DBWAFM6xx9diHjncGyGc5DhspuUf/mLjdWFbQ7TUe
f5JhH0W4uP48JQ0NPARKepIrMtZ7M8gsArDSvpkLN3UyLEOf7FRH9IQ=
-----END RSA PRIVATE KEY-----
EOF
    }
  }
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.configure_tgw_vpn_tunnels.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.instance_check_updates.arn}"
}

resource "aws_iam_role" "tgw_vpn_role" {
  name               = "tgw_vpn_role"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.instance-assume-role-policy.json}"
}

resource "aws_iam_role_policy" "tgw_add_vpn_policy" {
  name = "tgw_add_vpn_policy"
  role = "${aws_iam_role.tgw_vpn_role.id}"

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
                   "ec2:Describe*",
                   "ec2:CreateTags",
                   "ec2:CreateCustomerGateway",
                   "ec2:DeleteCustomerGateway",
                   "ec2:CreateVpnConnection",
                   "ec2:DeleteVpnConnection",
                   "ec2:AllocateAddress",
                   "ec2:AssociateAddress"
               ],
               "Effect": "Allow",
               "Resource": "*"
           }
       ],
       "Version": "2012-10-17"
}
  EOF
}
