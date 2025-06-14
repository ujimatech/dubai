resource "aws_secretsmanager_secret" "openrouter_api_key" {
  count       = var.openrouter_api_key != null ? 1 : 0
  name        = "${var.project_name}-openrouter-api-key"
  description = "OpenRouter API Key for ${var.project_name}"
}

resource "aws_secretsmanager_secret_version" "openrouter_api_key" {
  count                   = var.openrouter_api_key != null ? 1 : 0
  secret_id               = aws_secretsmanager_secret.openrouter_api_key[0].id
  secret_string_wo        = var.openrouter_api_key
  secret_string_wo_version = 1
}