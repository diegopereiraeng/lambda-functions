variable "vpc_cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_az1_cidr_block" {
  description = "CIDR block for the public subnet in AZ1."
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_az2_cidr_block" {
  description = "CIDR block for the public subnet in AZ2."
  type        = string
  default     = "10.0.2.0/24"
}

resource "aws_vpc" "lambda_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-lambda-vpc-${var.environment_name}"
    }
  )
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.lambda_vpc.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-igw-${var.environment_name}"
    }
  )
}

resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.lambda_vpc.id
  cidr_block              = var.public_subnet_az1_cidr_block
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true # For Lambda to pull images or talk to AWS services without NAT, if needed for some runtimes/setups

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-public-subnet-az1-${var.environment_name}"
    }
  )
}

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.lambda_vpc.id
  cidr_block              = var.public_subnet_az2_cidr_block
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-public-subnet-az2-${var.environment_name}"
    }
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lambda_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-public-rt-${var.environment_name}"
    }
  )
}

resource "aws_route_table_association" "public_az1" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_az2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "lambda_sg" {
  name        = "${var.project_name}-lambda-sg-${var.environment_name}"
  description = "Security group for Lambda function"
  vpc_id      = aws_vpc.lambda_vpc.id

  # Allow all outbound traffic by default
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ingress rules can be added if something needs to call the Lambda directly within the VPC (e.g. Application Load Balancer)
  # For now, assuming Lambda is invoked by AWS services or API Gateway (which is outside this SG)

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-lambda-sg-${var.environment_name}"
    }
  )
}

data "aws_availability_zones" "available" {}
