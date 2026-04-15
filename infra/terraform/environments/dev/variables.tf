variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "database_username" {
  type    = string
  default = "dealdrop"
}

variable "database_password" {
  type      = string
  sensitive = true
}
