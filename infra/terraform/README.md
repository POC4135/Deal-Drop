# DealDrop Terraform

This directory contains the AWS infrastructure foundation for Pass 2.

## Structure

- `modules/`: reusable AWS building blocks
- `environments/dev`: development topology with remote-state configuration
- `environments/staging`: staging topology
- `environments/prod`: production topology

## Provisioned foundation

- VPC with public and private subnets
- ECS/Fargate cluster and service foundation
- ECR repositories for API and workers
- Aurora PostgreSQL
- ElastiCache Redis
- S3 buckets for admin static hosting and proof/media uploads
- CloudFront distribution for the admin web app
- EventBridge + SQS queues with DLQs
- Cognito user pool and groups
- CloudWatch dashboards and alarms foundation

## Remote state

Use an S3 backend with DynamoDB locking. Because backend configuration is environment-specific, keep a local `backend.hcl` per environment and initialize with:

```bash
terraform -chdir=infra/terraform/environments/dev init -backend-config=backend.hcl
```

## Notes

- `admin_web` is modeled as a static export hosted on S3 + CloudFront.
- `api` and worker processes are modeled as ECS Fargate tasks.
- Queue names and service names mirror `packages/config/src/index.ts`.
