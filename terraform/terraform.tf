terraform {
  required_version = "~> 0.14"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.18.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 1.12.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 2.1.2"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 2.1"
    }

    template = {
      source  = "hashicorp/template"
      version = "~> 2.1"
    }
  }

  backend "s3" {
  }
}
