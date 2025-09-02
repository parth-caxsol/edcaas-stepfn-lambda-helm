# Subnets Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = [var.private_subnet_1, var.private_subnet_2, var.private_subnet_3]

  tags = {
    Name        = "${var.environment}-db-subnet-group"
    Environment = var.environment
    Terraform   = "true"
  }
}

# DB SG
resource "aws_security_group" "db_sg" {
  name        = "${var.environment}-db-sg"
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
    Name        = "${var.environment}-db-sg"
    Environment = var.environment
    Terraform   = "true"
  }
}

# Create DB
resource "aws_db_instance" "default" {
  allocated_storage      = 20
  db_name                = "devedc"
  engine                 = "postgres"
  engine_version         = "13.20"
  instance_class         = "db.t3.medium"
  username               = "postgres"
  password               = "rFkCbmwqBKgza8A"
  parameter_group_name   = "default.postgres13"
  skip_final_snapshot    = true
  publicly_accessible    = false
  storage_encrypted      = true
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  tags = {
    Name        = "${var.environment}-edc-db"
    Environment = var.environment
    Terraform   = "true"
  }
}
