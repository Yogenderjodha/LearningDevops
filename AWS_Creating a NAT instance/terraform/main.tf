# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main"
  }
}

# Create and attach internet gateway to vpc
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

# Create public subnet
resource "aws_subnet" "pub" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "main-pub"
  }
}

# Create private subnet
resource "aws_subnet" "pri" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "main-pri"
  }
}

# Create public route table
resource "aws_route_table" "pubrt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "main-pub"
  }
}

# Attach public subnet to public route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.pub.id
  route_table_id = aws_route_table.pubrt.id
}

# Create private route table
resource "aws_route_table" "prirt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-pri"
  }
}

# Attach public subnet to public route table
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.pri.id
  route_table_id = aws_route_table.prirt.id
}