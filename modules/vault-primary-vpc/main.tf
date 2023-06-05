module "vault_primary_vpc" {
  source = "../../main.tf"
  
  vpc_id = "{aws_vpc.winterfell.id}"
  region = "us-east-2"
  application_prefix = "winterfell"
  ingress_ssh_cidr_blocks = ["0.0.0.0/0"]
  vpc_cidr  = ""
  vault_api_port = 8200
  ingress_vault_cidr_blocks = ["0.0.0.0/0"]
  vault_cluster_port = 8201
  public_subnet = ["", "", ""]
  public_subnet_tags = ["arya-stark", "sansa-stark", "bran-stark"]
  aws_availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
  aws_iam_role = "winterfell-role"
  aws_iam_policy = "winterfell-policy"
}
