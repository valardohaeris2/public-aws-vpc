variable "vpc_id" {
  type        = string
  description = "(required) The VPC ID to host the cluster in"
}

variable "region" {
  type        = string
  description = "(required) The AWS region where resources are deployed"
}

variable "application_prefix" {
  description = "prefix to give to cloud entities"
}

variable "ingress_ssh_cidr_blocks" {
  type        = list(string)
  description = "List of CIDR blocks to allow SSH access to Vault instances. Not used if security_group_ids is set"
}

variable "vpc_cidr" {
  type        = string
  description = "Vault VPC CIDR"
}
variable "vault_api_port" {
  type        = number
  description = "Vault API port"
  default     = 8200
}

variable "ingress_vault_cidr_blocks" {
  type        = list(string)
  description = "List of CIDR blocks to allow API access to Vault."
}

variable "vault_cluster_port" {
  type        = number
  description = "Allow Vault nodes to communicate with each other in HA mode"
  default     = 8201

}

variable "public_subnet" {
  type        = list(any)
  description = "List of public subnet CIDRs"
}

variable "public_subnet_tags" {
  type        = list(any)
  description = "List of Names or tags for public subnets"
}

variable "aws_availability_zones" {
  type        = list(string)
  description = "AZ to use for subnets"
}

variable "aws_iam_role" {
  type = string
  description = "AWS IAM Role name"
}

variable "aws_iam_policy" {
  type = string
  description = "AWS IAM policy name"
}
