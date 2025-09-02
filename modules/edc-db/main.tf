# Fetched secrets from Secret Manager Service
data "aws_secretsmanager_secret" "rds_password" {
  name = "edc-db-secrets"
}

data "aws_secretsmanager_secret_version" "rds_password_version" {
  secret_id = data.aws_secretsmanager_secret.rds_password.id
}

locals {
  db_credentials = jsondecode(data.aws_secretsmanager_secret_version.rds_password_version.secret_string)
}

# Subnets Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-edc-db-subnet-group"
  subnet_ids = [var.private_subnet_1, var.private_subnet_2, var.private_subnet_3]

  tags = {
    Name        = "${var.environment}-edc-db-subnet-group"
    Environment = var.environment
    Terraform   = "true"
  }
}

# DB SG
resource "aws_security_group" "db_sg" {
  name        = "${var.environment}-edc-db-sg"
  description = "Allow access to RDS"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # security_groups = [aws_security_group.app_sg.id] # App layer SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-edc-db-sg"
    Environment = var.environment
    Terraform   = "true"
  }
}

# Create DB
resource "aws_db_instance" "default" {
  identifier            = "${var.environment}-edc-db"
  allocated_storage      = 20
  db_name                = "edcdb"
  engine                 = "postgres"
  engine_version         = "15.12"
  instance_class         = "db.t3.medium"
  username               = local.db_credentials.username
  password               = local.db_credentials.password
  parameter_group_name   = "default.postgres15"
  skip_final_snapshot    = true
  publicly_accessible    = false
  storage_encrypted      = true
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  allow_major_version_upgrade = true
  tags = {
    Name        = "${var.environment}-edc-db"
    Environment = var.environment
    Terraform   = "true"
  }
}

