variable "name" { type = string }
variable "subnet_ids" { type = list(string) }
variable "vpc_security_group_ids" { type = list(string) }
variable "database_name" { type = string }
variable "master_username" { type = string }
variable "master_password" { type = string }

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_rds_cluster" "this" {
  cluster_identifier      = "${var.name}-aurora"
  engine                  = "aurora-postgresql"
  engine_mode             = "provisioned"
  database_name           = var.database_name
  master_username         = var.master_username
  master_password         = var.master_password
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = var.vpc_security_group_ids
  skip_final_snapshot     = true
  backup_retention_period = 7
}

resource "aws_rds_cluster_instance" "primary" {
  identifier         = "${var.name}-aurora-1"
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version
}

output "cluster_arn" { value = aws_rds_cluster.this.arn }
output "endpoint" { value = aws_rds_cluster.this.endpoint }
