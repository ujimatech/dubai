variable "asg_desired_capacity" {
  description = "Desired number of instances in the ASG"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 2
}

variable "asg_min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 1
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3a.micro"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instances"
  type        = string
}

variable "tailscale_auth_key" {
  description = "Tailscale authentication key"
  type        = string
  sensitive   = true
}

variable "advertised_routes" {
  description = "Comma-separated list of routes to advertise (e.g., 10.0.0.0/24,10.0.1.0/24)"
  type        = string
}

variable "ssh_allowed_cidr_blocks" {
  description = "CIDR blocks allowed to SSH to the instances"
  type        = list(string)
  default     = []
}

variable "target_group_arns" {
  description = "List of target group ARNs to attach to the ASG"
  type        = list(string)
  default     = []
}