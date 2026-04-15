variable "name" { type = string }
variable "queues" { type = list(string) }

resource "aws_cloudwatch_event_bus" "this" {
  name = var.name
}

resource "aws_sqs_queue" "dlq" {
  for_each = toset(var.queues)
  name     = "${each.value}.dlq"
}

resource "aws_sqs_queue" "queue" {
  for_each                   = toset(var.queues)
  name                       = each.value
  visibility_timeout_seconds = 60
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[each.value].arn
    maxReceiveCount     = 5
  })
}

output "event_bus_name" { value = aws_cloudwatch_event_bus.this.name }
output "queue_arns" { value = { for key, queue in aws_sqs_queue.queue : key => queue.arn } }
