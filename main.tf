provider "aws" {
  region = "ap-south-1"
  access_key = "AKIAYLP2XLQTUWWO"
  secret_key = "FMy/90LWT8Rzok0EFEO963U/Z3SUK9dDPjhaj2173"
}
resource "aws_vpc" "main" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  tags = {
    Name = "myvpc1"
  }
}
resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "subnet1"
  }
}
resource "aws_subnet" "main1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "subnet2"
  }
}
resource "aws_instance" "web" {
  ami           = "ami-0b5bff6d9495eff69"
  instance_type = "t2.micro"
  key_name = "mykey12"
  associate_public_ip_address = false
  subnet_id = aws_subnet.main.id
  availability_zone = "ap-south-1a"
  vpc_security_group_ids = [aws_security_group.allow_tls1.id]
  tags = {
    Name = "os1"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "myvpc1_ig"
  }
}
resource "aws_instance" "web1" {
  ami           = "ami-000cbce3e1b899ebd"
  instance_type = "t2.micro"
  key_name = "mykey12"
  associate_public_ip_address = true
  subnet_id = aws_subnet.main1.id
  availability_zone = "ap-south-1b"
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
 
  tags = {
    Name = "os2"
  }
}
resource "aws_route_table" "r" {
  vpc_id = aws_vpc.main.id

  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
   tags = {
    Name = "routetableforig"
  }
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main1.id
  route_table_id = aws_route_table.r.id
}
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "For Public subnet i.e wordpress"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}
resource "aws_security_group" "allow_tls1" {
  name        = "allow_tls1"
  description = "For private subnet i.e Mysql"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "TLS from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups  = [aws_security_group.allow_tls.id]
  }
 ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.allow_tls2.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls1"
  }
}
resource "aws_security_group" "allow_tls2" {
  name        = "allow_tls2"
  description = "allow ssh"
  vpc_id      = aws_vpc.main.id
 ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls2"
  }
}
resource "aws_instance" "web2" {
  ami = "ami-0ebc1ac48dfd14136"
  instance_type = "t2.micro"
  key_name = "mykey12"
  associate_public_ip_address = true
  subnet_id = aws_subnet.main1.id
  availability_zone = "ap-south-1b"
  vpc_security_group_ids = [aws_security_group.allow_tls2.id]
 
  tags = {
    Name = "bastionhostos"
  }
}

resource "aws_eip" "lb" {
  vpc      = true
}
resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.lb.id
  subnet_id     = aws_subnet.main1.id
  tags = {
    Name = "mynatgateway"
  }
}
resource "aws_route_table" "r1" {
  vpc_id = aws_vpc.main.id

  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.gw.id
  }
   tags = {
    Name = "routetableformysql"
  }
}
resource "aws_route_table_association" "a1" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.r1.id
}