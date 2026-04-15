variable "name" { type = string }

resource "aws_cognito_user_pool" "this" {
  name = "${var.name}-users"

  auto_verified_attributes = ["email"]

  schema {
    name                     = "email"
    attribute_data_type      = "String"
    required                 = true
    mutable                  = true
    developer_only_attribute = false
  }
}

resource "aws_cognito_user_pool_client" "this" {
  name         = "${var.name}-client"
  user_pool_id = aws_cognito_user_pool.this.id
}

resource "aws_cognito_user_group" "admin" {
  name         = "dealdrop-admin"
  user_pool_id = aws_cognito_user_pool.this.id
}

resource "aws_cognito_user_group" "moderator" {
  name         = "dealdrop-moderator"
  user_pool_id = aws_cognito_user_pool.this.id
}

resource "aws_cognito_user_group" "user" {
  name         = "dealdrop-user"
  user_pool_id = aws_cognito_user_pool.this.id
}

output "user_pool_id" { value = aws_cognito_user_pool.this.id }
output "client_id" { value = aws_cognito_user_pool_client.this.id }
