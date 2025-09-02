# Get Available AZs
data "aws_availability_zones" "available" {}

# VPC
resource "aws_vpc" "dev_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name        = "${var.environment}-vpc"
    Environment = "${var.environment}"
    Terraform   = "true"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "dev_igw" {
  vpc_id = aws_vpc.dev_vpc.id
  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
    Terraform   = "true"
  }
}

# Create an Elastic IPs for the NAT Gateway
resource "aws_eip" "nat_eip_1" {
  domain = "vpc"
  tags = {
    Name      = "${var.environment}-nat-eip"
    Terraform = "true"
  }
}

# NAT Gateway for Outbound Traffic
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip_1.id
  subnet_id     = aws_subnet.public_subnet_1.id
  tags = {
    Name      = "${var.environment}-nat-gateway"
    Terraform = "true"
  }
  depends_on = [aws_internet_gateway.dev_igw]
}

# 3 Public Subnets
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.dev_vpc.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-public-subnet-1"
    Environment = var.environment
    Terraform   = "true"
    Type        = "Public"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.dev_vpc.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-public-subnet-2"
    Environment = var.environment
    Terraform   = "true"
    Type        = "Public"
  }
}

resource "aws_subnet" "public_subnet_3" {
  vpc_id                  = aws_vpc.dev_vpc.id
  cidr_block              = var.public_subnet_3_cidr
  availability_zone       = data.aws_availability_zones.available.names[2]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-public-subnet-3"
    Environment = var.environment
    Terraform   = "true"
    Type        = "Public"
  }
}

# 3 Private Subnets
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.dev_vpc.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "${var.environment}-private-subnet-1"
    Environment = var.environment
    Terraform   = "true"
    Type        = "Private"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.dev_vpc.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name        = "${var.environment}-private-subnet-2"
    Environment = var.environment
    Terraform   = "true"
    Type        = "Private"
  }
}

resource "aws_subnet" "private_subnet_3" {
  vpc_id            = aws_vpc.dev_vpc.id
  cidr_block        = var.private_subnet_3_cidr
  availability_zone = data.aws_availability_zones.available.names[2]

  tags = {
    Name        = "${var.environment}-private-subnet-3"
    Environment = var.environment
    Terraform   = "true"
    Type        = "Private"
  }
}

# Public Route Table Used Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.dev_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_igw.id
  }
  tags = {
    Name      = "${var.environment}-public-route-table"
    Terraform = "true"
  }
}

# Private Route Table - Used NAT Gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.dev_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    Name      = "${var.environment}-private-route-table"
    Terraform = "true"
  }
}

# Associate route tables with subnets
# Public
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_3" {
  subnet_id      = aws_subnet.public_subnet_3.id
  route_table_id = aws_route_table.public.id
}
# private
resource "aws_route_table_association" "private_app_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private_app_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private_app_3" {
  subnet_id      = aws_subnet.private_subnet_3.id
  route_table_id = aws_route_table.private.id
}
