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
  name = "dealdrop-dev"
}

module "networking" {
  source               = "../../modules/networking"
  name                 = local.name
  vpc_cidr             = "10.40.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.40.1.0/24", "10.40.2.0/24"]
  private_subnet_cidrs = ["10.40.11.0/24", "10.40.12.0/24"]
}

resource "aws_security_group" "app" {
  name   = "${local.name}-app"
  vpc_id = module.networking.vpc_id
}

module "ecr" {
  source       = "../../modules/ecr"
  name         = local.name
  repositories = ["api", "workers-read-model", "workers-trust", "workers-gamification"]
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

module "admin_bucket" {
  source      = "../../modules/s3_bucket"
  bucket_name = "${local.name}-admin-web"
}

module "proof_bucket" {
  source      = "../../modules/s3_bucket"
  bucket_name = "${local.name}-proofs"
}

module "media_bucket" {
  source      = "../../modules/s3_bucket"
  bucket_name = "${local.name}-media"
}

module "cloudfront" {
  source             = "../../modules/cloudfront"
  name               = local.name
  origin_domain_name = module.admin_bucket.bucket_regional_domain_name
}

module "eventing" {
  source = "../../modules/eventbridge_sqs"
  name   = "${local.name}-bus"
  queues = [
    "dealdrop.read-model.projector",
    "dealdrop.trust.scorer",
    "dealdrop.gamification.projector",
    "dealdrop.moderation.dedupe",
    "dealdrop.leaderboard.refresh",
    "dealdrop.listings.stale-scan",
  ]
}

module "cognito" {
  source = "../../modules/cognito"
  name   = local.name
}

module "api_service" {
  source             = "../../modules/ecs_service"
  name               = "${local.name}-api"
  cluster_name       = "${local.name}-cluster"
  subnet_ids         = module.networking.private_subnet_ids
  security_group_ids = [aws_security_group.app.id]
  container_image    = "public.ecr.aws/docker/library/nginx:latest"
  container_port     = 3000
  cpu                = 512
  memory             = 1024
  desired_count      = 1
  environment = {
    APP_ENV           = "dev"
    DATABASE_URL      = module.database.endpoint
    REDIS_URL         = module.redis.primary_endpoint
    EVENT_BUS_NAME    = module.eventing.event_bus_name
    COGNITO_USER_POOL = module.cognito.user_pool_id
  }
}

module "observability" {
  source          = "../../modules/observability"
  name            = local.name
  queue_name      = "dealdrop.trust.scorer"
  redis_id        = "${local.name}-redis"
  db_cluster_id   = "${local.name}-aurora"
  ecs_cluster_name = module.api_service.cluster_name
  dashboard_body  = jsonencode({ widgets = [] })
}
