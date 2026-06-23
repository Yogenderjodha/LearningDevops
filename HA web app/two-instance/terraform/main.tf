locals {
  vpc_name    = "${var.project}-vpc"
  igw_name    = "${var.project}-igw"
  public_rt   = "${var.project}-pub-rt"
  private_rt  = "${var.project}-pri-rt"
  server_sg   = "${var.project}-pri-sg"
  alb_sg      = "${var.project}-alb-sg"
  server_name = "${var.project}-flask"
  alb_tg      = "${var.project}-flask-tg"
}


##### Create VPC
resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = local.vpc_name
  }
}


##### Create internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = local.igw_name
  }
}


##### Create two public subnets
resource "aws_subnet" "public" {
  for_each = var.public_subnets


  vpc_id     = aws_vpc.main.id
  cidr_block = each.value.cidr

  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name = each.key
  }
}


##### Create two private subnets
resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = {
    Name = each.key
  }
}


##### Create route table for public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }


  tags = {
    Name = local.public_rt
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

##### Create route table for private subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route = []

  tags = {
    Name = local.private_rt
  }
}


resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}


##### Find AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["flask"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["591164067111"] # Self
}


##### ALB Security groups
resource "aws_security_group" "alb" {
  name        = local.alb_sg
  description = "Allow all inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = local.alb_sg
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_alb_http_ipv4" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

##### EC2 Security groups
resource "aws_security_group" "server" {
  name        = local.server_sg
  description = "Allow inbound traffic from ALB SG, SSH and all outbound traffic"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = local.server_sg
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_server_ipv4" {
  security_group_id            = aws_security_group.server.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 8080
  ip_protocol                  = "tcp"
  to_port                      = 8080
}

resource "aws_vpc_security_group_ingress_rule" "allow_server_ssh" {
  security_group_id = aws_security_group.server.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_port_server_ssh" {
  security_group_id = aws_security_group.server.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}



##### Launch EC2 from AMI to private subnets
resource "aws_instance" "server" {
  # for_each = aws_subnet.private["pri-1"].id

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = "california-learning"

  vpc_security_group_ids = [aws_security_group.server.id]
  # subnet_id       = each.value
  subnet_id = aws_subnet.private["pri-1"].id
  #subnet_id = aws_subnet.public["pub-1"].id

  tags = {
    Name = local.server_name
  }
}



##### Create Target group
resource "aws_lb_target_group" "tg" {
  name     = local.alb_tg
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# Register instances to TG
resource "aws_lb_target_group_attachment" "alb_tg_attach" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.server.id
  port             = 8080
}