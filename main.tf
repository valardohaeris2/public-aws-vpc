terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>4.16"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">=3.1.0"
    }
  }
}

#TFC Backend for tf state
 terraform {
   cloud {
     organization = "<org_name>"

     workspaces {
       name = "<workspace_name>"
     }
   }
 }

# Configure the AWS Provider 
provider "aws" {
  region = var.region
}

# Create a VPC in us-east-2
resource "aws_vpc" "winterfell" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.application_prefix}-vpc"
  }
}

# Create three subnets 
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet)
  vpc_id                  = "${aws_vpc.winterfell.id}"         
  cidr_block              = var.public_subnet[count.index]
  availability_zone       = var.aws_availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    "Name" = var.public_subnet_tags[count.index]
  }
}

# Create an Internet Gateway 
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.winterfell.id  
  tags = {
    "Name" = "${var.application_prefix}-igw"
  }
}

# Create a Route Table 
resource "aws_route_table" "rtbl" {
  vpc_id = aws_vpc.winterfell.id 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    "Name" = "${var.application_prefix}-rt"
  }
}

# AWS Route Table Association 
resource "aws_route_table_association" "public" {
  count     = length(var.public_subnet)
  subnet_id = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.rtbl.id
}

# Create an AWS Security Group
resource "aws_security_group" "vault_security_group" {
  vpc_id      = aws_vpc.winterfell.id   
  name        = format("%s-security-group", var.application_prefix)
  description = "Vault Security Group"

  ingress {
    description = "all traffic"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "all traffic"
    from_port   = 0
    protocol    = -1
    to_port     = 0
  }

  tags = {
    "Name" = "${var.application_prefix}-sg"
  }
}

resource "aws_security_group_rule" "allow_ssh_communication" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.ingress_ssh_cidr_blocks
  description       = "Allow SSH access to Vault nodes"
  security_group_id = aws_security_group.vault_security_group.id
}

resource "aws_security_group_rule" "allow_vault_api_communication" {
  type              = "ingress"
  from_port         = var.vault_api_port
  to_port           = var.vault_api_port
  protocol          = "tcp"
  cidr_blocks       = var.ingress_vault_cidr_blocks
  description       = "Allow API access to Vault nodes"
  security_group_id = aws_security_group.vault_security_group.id
}

resource "aws_security_group_rule" "allow_vault_cluster_communication" {
  type              = "ingress"
  from_port         = var.vault_cluster_port
  to_port           = var.vault_cluster_port
  self              = true
  protocol          = "tcp"
  description       = "Allow Vault nodes to communicate with each other in HA mode"
  security_group_id = aws_security_group.vault_security_group.id

}


#---------------------------------------------------------
# Create IAM Role  
#---------------------------------------------------------
resource "aws_iam_role" "role" {
  name               = var.aws_iam_role            
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

#---------------------------------------------------------
# Create IAM Policy for Role 
#---------------------------------------------------------
resource "aws_iam_policy" "policy" {
  name   = var.aws_iam_policy      
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

#---------------------------------------------------------
# Create IAM Role Policy Document Attachment 
#---------------------------------------------------------
resource "aws_iam_role_policy_attachment" "vault-role-attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}

#-----------------------------------------------------------
# Create a KMS Key for Auto-Unseal and S3 Bucket encryption 
#-----------------------------------------------------------
resource "aws_kms_key" "vault-kms" {
  description = "Vault KMS key for auto-unseal and S3 encryption"
  policy      = <<EOT
  {
    "Id": "key-consolepolicy-3",
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::....."
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow access for Key Administrators",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::.....",
                    "arn:aws:iam::.....",
                    "arn:aws:iam::....."
                ]
            },
            "Action": [
                "kms:Create*",
                "kms:Describe*",
                "kms:Enable*",
                "kms:List*",
                "kms:Put*",
                "kms:Update*",
                "kms:Revoke*",
                "kms:Disable*",
                "kms:Get*",
                "kms:Delete*",
                "kms:TagResource",
                "kms:UntagResource",
                "kms:ScheduleKeyDeletion",
                "kms:CancelKeyDeletion"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow use of the key",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::.....",
                    "arn:aws:iam::.....",
                    "arn:aws:iam::....."
                ]
            },
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow attachment of persistent resources",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::.....",
                    "arn:aws:iam::.....",
                    "arn:aws:iam::....."
                ]
            },
            "Action": [
                "kms:CreateGrant",
                "kms:ListGrants",
                "kms:RevokeGrant"
            ],
            "Resource": "*",
            "Condition": {
                "Bool": {
                    "kms:GrantIsForAWSResource": "true"
                }
            }
        }
    ]
}
EOT
}

#------------------------------------------
# Create KMS key alias 
#------------------------------------------
resource "aws_kms_alias" "vault-kms-alias" {
  name          = "alias/${var.application_prefix}-kms" 
  target_key_id = aws_kms_key.vault-kms.key_id
}



#==================================================================================
#                         Outputs
#==================================================================================
# output "vpc_id" {
#   value = aws_vpc.winterfell.id #var.network
# }

# output "vpc_name" {
#   value = format("%s-vpc", var.application_prefix)
# }

# output "aws_region" {
#   value = var.region
# }
