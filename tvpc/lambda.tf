resource "aws_cloudformation_stack" "lambdas" {
  count        = "${var.primary_region}"
  name         = "akbhat-transit-vpc-lambdas"
  capabilities = ["CAPABILITY_IAM"]

  parameters = {
    SshPublicKey          = "${file(var.public_key_path)}"
    AllowedSshIpAddress   = "${var.allowed_ssh_ipadd}"
    TerminationProtection = "${var.enable_term_protection}"
    TransitVPC            = "${aws_vpc.tvpc.id}"
#    PubSubnet11           = "${var.pub_mgmt_subnet_az1}"
    VPCPubSub11           = "${aws_subnet.VPCPubSub11.id}"
    vSRXInterface11PvtIP  = "${element(aws_network_interface.vSRXInterface11.private_ips,0)}"
#    PubSubnet21           = "${var.pub_mgmt_subnet_az2}"
    VPCPubSub21           = "${aws_subnet.VPCPubSub21.id}"
    vSRXInterface21PvtIP  = "${element(aws_network_interface.vSRXInterface21.private_ips,0)}"
    PubSubnet12           = "${var.pub_data_subnet_az1}"
    PubSubnet22           = "${var.pub_data_subnet_az2}"
    vSRXEip11             = "${aws_eip.vsrx1_data_eip.public_ip}"
    vSRXEip21             = "${aws_eip.vsrx2_data_eip.public_ip}"
    VSRXType              = "${var.vsrx_ec2_type}"
    PreferredPathTag      = "${var.preferred_path_tag}"
    SpokeTag              = "${var.vpc_spoke_tag}"
    SpokeTagValue         = "${var.vpc_spoke_tag_value}"
    BgpAsn                = "${var.bgp_asn}"
    S3Prefix              = "${var.s3_prefix_key_names}"
    AccountId             = "${var.accountid}"
  }

  template_body = "${file(var.cf_template)}"

  timeouts {
    create = "5m"
    delete = "5m"
  }
}
