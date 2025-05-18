# main.tf

locals {
  association_name = var.association_name != null ? var.association_name : "${var.document_name}-association"

  # Determine if bash_script is a file path or direct content
  script_content = fileexists(var.bash_script) ? file(var.bash_script) : var.bash_script

  # Construct SSM document parameters
  ssm_parameters = {
    for key, param in var.set_document_parameters : key => {
      type        = param.type
      description = param.description
      default     = try(param.default, null)
    }
  }
}

# Create the SSM document with the bash script
resource "aws_ssm_document" "script_document" {
  name            = var.document_name
  document_type   = "Command"
  document_format = "YAML"

  content = yamlencode({
    schemaVersion = "2.2"
    description   = "SSM document to execute a bash script"
    parameters    = local.ssm_parameters
    mainSteps = [{
      action = "aws:runShellScript"
      name   = "runScript"
      inputs = {
        runCommand = [
          local.script_content
          # Replace parameter placeholders in the script

          # replace(
          #   local.script_content,
          #   "/\\{\\{ (\\w+) \\}\\}/",
          #   "{{ ssm:$1 }}"
          # )
        ]
      }
    }]
  })
}

# Create an SSM association to run the document on targeted instances
resource "aws_ssm_association" "script_association" {
  count = var.enable_association ? 1 : 0

  name             = aws_ssm_document.script_document.name
  association_name = local.association_name

  parameters = var.parameters
  
  targets {
    key    = "tag:${keys(var.target_tags)[0]}"
    values = [values(var.target_tags)[0]]
  }

  schedule_expression = var.schedule_expression
  compliance_severity = var.compliance_severity
  max_concurrency     = var.max_concurrency
  max_errors          = var.max_errors
}