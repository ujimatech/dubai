# lambda.tf

resource "aws_lambda_function" "proxy_api_handler" {
  function_name = "${local.name_prefix}-proxy-api-handler"
  description   = "Bedrock Proxy API Handler"
  
  architectures = ["arm64"]
  image_uri     = var.lambda_image_uri
  package_type  = "Image"
  
  environment {
    variables = {
      API_KEY_SECRET_ARN            = var.bedrock_api_key_secret_arn
      DEBUG                         = var.debug_mode
      DEFAULT_EMBEDDING_MODEL       = var.default_embedding_model
      DEFAULT_MODEL                 = var.default_model
      ENABLE_CROSS_REGION_INFERENCE = var.enable_cross_region_inference
    }
  }

  vpc_config {
    subnet_ids         = var.lambda_subnet_ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  ephemeral_storage {
    size = var.ephemeral_storage_size
  }

  logging_config {
    log_format = "Text"
    log_group  = "/aws/lambda/${local.name_prefix}-proxy-api-handler"
  }

  role = aws_iam_role.lambda_execution_role.arn

}