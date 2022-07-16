provider "aws" {
  region  = "us-east-1"
  access_key = ""
  secret_key = ""
}
#create vpc
 resource "aws_vpc" "prodvpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
 
Name = "production vpc"
  }
}
#create internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prodvpc.id
  }
  #create route table
resource "aws_route_table" "prodroutetable" {
  vpc_id = aws_vpc.prodvpc.id
  

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "prod"
  }
}
#create a subnet
  resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.prodvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "prodsubnet"
  }
}
#assosciate subnet with a route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.prodroutetable.id
}
#create a security group
resource "aws_security_group" "allow_web" {
  name        = "allow_webtraffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.prodvpc.id

  ingress {
    description      = "https from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
  ingress {
    description      = "http from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "allow_web"
  }
}
#create network interface
resource "aws_network_interface" "webservernic" {
  subnet_id       = aws_subnet.subnet1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

  }
  #assign elastic eip to network interface created
  resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.webservernic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw]
}
#create instance
resource "aws_instance" "web" {
  ami           = "ami-09d56f8956ab235b3"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name ="main-key" 

  network_interface {
    device_index=0
    network_interface_id=aws_network_interface.webservernic.id
    }

    user_data = <<-EOF
  #!/bin/bash
   sudo apt update -y
    sudo apt istall apache2 -y
    sudo systemctl apache2
    sudo bash -c 'echo your very first web server>/var/www/html/index.html'
  EOF

  tags = {
    Name = "webserver"
ddddddd
  }
}


    
  
