variable "name" { type = string }
variable "repositories" { type = list(string) }

resource "aws_ecr_repository" "repo" {
  for_each             = toset(var.repositories)
  name                 = "${var.name}/${each.value}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

output "repository_urls" {
  value = { for key, repo in aws_ecr_repository.repo : key => repo.repository_url }
}
