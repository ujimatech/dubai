resource "aws_db_subnet_group" "aurora_subnet_group" {
  name       = "${var.project_name}-aurora-subnet-group"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier = "${var.project_name}-cluster"
  engine             = "aurora-postgresql"
  engine_mode        = "provisioned"
  engine_version     = "16.4"
  database_name      = "${var.project_name}"
  master_username    = var.postgres_db_user
  master_password    = var.postgres_db_password # Store this securely in variables

  # Cost optimization settings
  serverlessv2_scaling_configuration {
    min_capacity             = 0.0 # Minimum ACU (Aurora Capacity Units)
    max_capacity             = 1.0 # Maximum ACU
    seconds_until_auto_pause = 300 # 5 minutes
  }

  # Enabling these features for cost savings
  skip_final_snapshot  = true
  deletion_protection  = false # Set to true in production
  enable_http_endpoint = true

  # Network settings
  db_subnet_group_name   = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids = [aws_security_group.aurora_sg.id]
}

resource "aws_rds_cluster_instance" "aurora_instance" {
  cluster_identifier = aws_rds_cluster.aurora_cluster.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora_cluster.engine
  engine_version     = aws_rds_cluster.aurora_cluster.engine_version
}

resource "aws_security_group" "aurora_sg" {
  name        = "${var.project_name}-aurora-sg"
  description = "Security group for Aurora Serverless"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    # Adjust this based on your security requirements
    security_groups = [module.tailscale.security_group_id, aws_security_group.ecs.id]
  }
}
