module "tvpc-us-east-1" {
  source = "./tvpc"
  primary_region = 0 
  public_key_path = "./akbhat_transit_vsrx.pub"
  cf_template = "lambda.template"
  region = "us-east-1"
  ami_name_filter = "*junos-vsrx3-x86-64-19.1R1.6-std--pm.img"
#  ami_name_filter = "*srx*18.4R1.8--pm*"
}

#module "tvpc-us-west-2" {
#  source = "./tvpc"
#  primary_region = 0
#  public_key_path = "./akbhat_transit_vsrx.pub"
#  cf_template = "lambda.template"
#  region = "us-west-2"
#  ami_name_filter = "*srx*18.4R1.8--pm*"
#}
