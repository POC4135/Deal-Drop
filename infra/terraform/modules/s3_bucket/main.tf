variable "bucket_name" { type = string }
variable "force_destroy" { type = bool, default = false }

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "bucket_id" { value = aws_s3_bucket.this.id }
output "bucket_regional_domain_name" { value = aws_s3_bucket.this.bucket_regional_domain_name }
