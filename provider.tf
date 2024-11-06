terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.74.0"
    }
    tls = {
      source  = "hashicorp/tls" 
      version = "4.0.6"
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

# Configure TLS Provider
provider "tls" {
}
