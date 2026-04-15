variable "name" { type = string }
variable "dashboard_body" { type = string }
variable "queue_name" { type = string }
variable "redis_id" { type = string }
variable "db_cluster_id" { type = string }
variable "ecs_cluster_name" { type = string }

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "${var.name}-ops"
  dashboard_body = var.dashboard_body
}

resource "aws_cloudwatch_metric_alarm" "queue_depth" {
  alarm_name          = "${var.name}-queue-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = 50
  dimensions          = { QueueName = var.queue_name }
}

resource "aws_cloudwatch_metric_alarm" "redis_memory" {
  alarm_name          = "${var.name}-redis-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  dimensions          = { CacheClusterId = var.redis_id }
}

resource "aws_cloudwatch_metric_alarm" "database_cpu" {
  alarm_name          = "${var.name}-database-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 75
  dimensions          = { DBClusterIdentifier = var.db_cluster_id }
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  alarm_name          = "${var.name}-ecs-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 75
  dimensions          = { ClusterName = var.ecs_cluster_name }
}
