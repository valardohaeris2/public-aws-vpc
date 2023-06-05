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

# Configure the AWS Provider 
provider "aws" {
  region = "us-east-2"
}

provider "tls" {}
