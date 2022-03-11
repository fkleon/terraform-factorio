terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.13"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 2.1"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 2.1"
    }
  }
  required_version = ">= 0.13"
}
