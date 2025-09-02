# Create a custom security group
resource "aws_security_group" "web_sg" {
  name        = "bastion-sg"
  vpc_id      = var.vpc_id

  # Egress rule to allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-bastion-SG"
    Environment = "${var.environment}"
    Terraform   = "true"
  }
}

# Fetch latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

# Create ec2 Instances
resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = var.public_subnet_1
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    exec > /var/log/user-data.log 2>&1
    set -x
    sudo apt update -y
    sudo apt install -y postgresql
  EOF

  tags = {
    Name        = "${var.environment}-bastion-host"
    Environment = "${var.environment}"
    Terraform   = "true"
  }
}
