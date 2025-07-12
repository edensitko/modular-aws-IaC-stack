resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "public-a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "${var.vpc_name}-public-subnet-a"
  }
}

resource "aws_subnet" "public-b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "${var.vpc_name}-public-subnet-b"
  }
}