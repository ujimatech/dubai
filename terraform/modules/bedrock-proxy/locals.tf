# locals.tf

locals {
  # Basic naming and tagging
  name_prefix = "${var.project_name}-${var.environment}"

  # Lambda related
  lambda_function_name = "${local.name_prefix}-proxy-api-handler"
}