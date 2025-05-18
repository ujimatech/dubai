# variables.tf

variable "document_name" {
  description = "Name for the SSM document"
  type        = string
}

variable "bash_script" {
  description = "Path to the bash script file or the script content directly"
  type        = string
}

variable "set_document_parameters" {
  description = "Parameters to define in the SSM document"
  type        = map(object({
    type        = string
    description = string
    default     = optional(string)
  }))
  default     = {}
}

variable "parameters" {
  description = "Parameter values to pass to the script execution"
  type        = map(string)
  default     = {}
}

variable "enable_association" {
  description = "Whether to create an SSM association to run the document automatically"
  type        = bool
  default     = true
}

variable "target_tags" {
  description = "Tags to use for targeting EC2 instances"
  type        = map(string)
  default     = {}
}

variable "association_name" {
  description = "Name for the SSM association"
  type        = string
  default     = null
}

variable "schedule_expression" {
  description = "Schedule expression for when the document should be executed"
  type        = string
  default     = "rate(30 minutes)"
}

variable "compliance_severity" {
  description = "Severity level for compliance reporting"
  type        = string
  default     = "MEDIUM"
  validation {
    condition     = contains(["CRITICAL", "HIGH", "MEDIUM", "LOW", "UNSPECIFIED"], var.compliance_severity)
    error_message = "Compliance severity must be one of: CRITICAL, HIGH, MEDIUM, LOW, UNSPECIFIED."
  }
}

variable "max_concurrency" {
  description = "Maximum number of targets to run the document on concurrently"
  type        = string
  default     = "50%"
}

variable "max_errors" {
  description = "Maximum number of errors before the execution is considered failed"
  type        = string
  default     = "50%"
}