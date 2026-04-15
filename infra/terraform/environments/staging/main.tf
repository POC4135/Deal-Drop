terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.94"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

locals {
  name = "dealdrop-staging"
}

module "networking" {
  source               = "../../modules/networking"
  name                 = local.name
  vpc_cidr             = "10.41.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.41.1.0/24", "10.41.2.0/24"]
  private_subnet_cidrs = ["10.41.11.0/24", "10.41.12.0/24"]
}

resource "aws_security_group" "app" {
  name   = "${local.name}-app"
  vpc_id = module.networking.vpc_id
}

module "database" {
  source                 = "../../modules/aurora_postgres"
  name                   = local.name
  subnet_ids             = module.networking.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.app.id]
  database_name          = "dealdrop"
  master_username        = var.database_username
  master_password        = var.database_password
}

module "redis" {
  source             = "../../modules/redis"
  name               = local.name
  subnet_ids         = module.networking.private_subnet_ids
  security_group_ids = [aws_security_group.app.id]
}
