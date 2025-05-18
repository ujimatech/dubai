# variables.tf

variable "fleet_prefix" {
  description = "Prefix to be used for naming resources associated with the EC2 scale set"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "instance_count" {
  description = "Number of EC2 instances to maintain in the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "subnet_ids" {
  description = "List of subnet IDs where instances will be launched"
  type        = list(string)
}

variable "external_launch_template_id" {
  description = "ID of an externally created launch template to use for the ASG"
  type        = string
}

variable "external_launch_template_version" {
  description = "Version of the specified launch template to use"
  type        = string
  default     = "$Latest"
}

variable "min_size" {
  description = "Minimum size of the Auto Scaling Group"
  type        = number
  default     = null
}

variable "max_size" {
  description = "Maximum size of the Auto Scaling Group"
  type        = number
  default     = null
}

variable "health_check_type" {
  description = "Health check type for the Auto Scaling Group (EC2 or ELB)"
  type        = string
  default     = "EC2"
}

variable "health_check_grace_period" {
  description = "Time (in seconds) after instance comes into service before checking health"
  type        = number
  default     = 300
}

variable "additional_tags" {
  description = "Additional tags to apply to the Auto Scaling Group and instances"
  type        = map(string)
  default     = {}
}

variable "target_group_arns" {
  description = "List of target group ARNs to associate with the Auto Scaling Group"
  type        = list(string)
  default     = []
}

variable "desired_capacity" {
  description = "The desired capacity of the Auto Scaling Group"
  type        = number
  default     = null
}

variable "termination_policies" {
  description = "A list of policies to decide how the instances in the Auto Scaling Group should be terminated"
  type        = list(string)
  default     = ["Default"]
}

variable "enable_ssm_management" {
  description = "Whether to enable SSM management for the instances"
  type        = bool
  default     = true
}

variable "wait_for_capacity_timeout" {
  description = "A maximum duration that Terraform should wait for ASG instances to be healthy"
  type        = string
  default     = "10m"
}