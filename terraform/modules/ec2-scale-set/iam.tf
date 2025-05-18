# iam.tf

# Retrieve the launch template to get the instance profile
data "aws_launch_template" "this" {
  id = var.external_launch_template_id
}

# Get the role name from the instance profile attached to the launch template
data "aws_iam_instance_profile" "ec2_profile" {
  name = try(data.aws_launch_template.this.iam_instance_profile[0].name, null)
}

# Attach SSM managed policy to the IAM role
resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  role       = data.aws_iam_instance_profile.ec2_profile.role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}