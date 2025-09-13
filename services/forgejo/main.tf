resource "aws_secretsmanager_secret" "forgejo_db_credentials" {
  name        = "forgejo-db-credentials"
  description = "Forgejo application database credentials"
}
