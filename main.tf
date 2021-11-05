provider "aws" {
  profile    = "${var.profile}"
  region     = "${var.region}"

}




variable "region" {
        default = "us-west-2"
}

variable "profile" {
    description = "default"
}

# variable "instance_type" {
#   type = string
# }
#  variable "instance_name" {
#    type = string
#  }

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

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "flugel_server" {
  ami           = data.aws_ami.ubuntu.id 
  instance_type = "t2.micro"
  key_name = "main-key"

  user_data = <<-EOF
  #!/bin/bash
  echo "*** Installing apache2"
  sudo apt update -y
  sudo apt install apache2 -y
  echo "*** Completed Installing apache2"
  EOF


  tags = {
    Name = "Flugel"
    Owner = "InfraTeam"
    
  }
}

resource "aws_s3_bucket" "flugel_bucket" {
  bucket = "flugel-bucket"
  acl    = "private"

  tags = {
    Name = "Flugel"
    Owner = "InfraTeam"
  }
}

output "instance_id" {
  description = "instance_id value"
  value = aws_instance.flugel_server.id
}

output "bucket_id" {
  description = "bucket_id value"
  value = aws_s3_bucket.flugel_bucket.id
}


# Create a VPC
resource "aws_vpc" "app_vpc" {
  cidr_block = "178.0.0.0/16"

  tags = {
    Name = "app-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.app_vpc.id

  tags = {
    Name = "vpc_igw"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "178.0.10.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_rt"
  }
}

resource "aws_route_table_association" "public_rt_asso" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "sg" {
  name        = "allow_ssh_http"
  description = "Allow ssh http inbound traffic"
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh_http"
  }
}



output "flugel_server_ip" {
    value = aws_instance.flugel_server.public_ip
}
