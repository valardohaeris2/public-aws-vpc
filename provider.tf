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
