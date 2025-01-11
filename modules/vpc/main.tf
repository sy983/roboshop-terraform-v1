## VPC creation
resource "aws_vpc" "main" {
  cidr_block       = var.cidr

  tags = {
    Name = "${var.env}-vpc"
  }
}

## Subnet creation
resource "aws_subnet" "public" {
  count = length(var.public_subnets)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "public_subnets-${split("-", var.availability_zones[count.index])[2]}"
  }
}

resource "aws_subnet" "web" {
  count = length(var.web_subnets)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.web_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "web_subnets-${split("-", var.availability_zones[count.index])[2]}"
  }
}

resource "aws_subnet" "app" {
  count = length(var.app_subnets)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.app_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "app_subnets-${split("-", var.availability_zones[count.index])[2]}"
  }
}

resource "aws_subnet" "db" {
  count = length(var.db_subnets)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.db_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "db_subnets-${split("-", var.availability_zones[count.index])[2]}"
  }
}

## Route tables

resource "aws_route_table" "public" {
  count = length(var.public_subnets)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "10.0.1.0/24"
    gateway_id = aws_internet_gateway.example.id
  }


  tags = {
    Name = "example"
  }
}