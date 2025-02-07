terraform {
    required_providers {
        aws = {
        source  = "hashicorp/aws"
        version = "~> 5.0"
        }
    }
}

provider "aws" {
    region = "us-east-1"
}

resource "aws_vpc" "honey_net" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = {
        Name = "honey_net"
    }
}

resource "aws_subnet" "honey_subnet" {
    availability_zone = "us-east-1a"
    vpc_id     = aws_vpc.honey_net.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true

    tags = {
        Name = "honey_subnet"
    }
}

resource "aws_internet_gateway" "honey_gateway" {
    vpc_id = aws_vpc.honey_net.id

    tags = {
        Name = "honey_gateway"
    }
}

resource "aws_route_table" "honey_route_table" {
    vpc_id = aws_vpc.honey_net.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.honey_gateway.id
    }

    tags = {
        Name = "honey_route_table"
    }
}

resource "aws_route_table_association" "honey_route_table_association" {
    subnet_id      = aws_subnet.honey_subnet.id
    route_table_id = aws_route_table.honey_route_table.id
}

resource "aws_security_group" "honeypot_server_sg" {
    name        = "honeypot_server_sg"
    description = "Allow inbound traffic on port 22 and 2022"
    vpc_id = aws_vpc.honey_net.id

    # Allow SSH honeypot traffic in
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow real SSH traffic in
    ingress {
        from_port   = 2022
        to_port     = 2022
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow all traffic out
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "honeypot_server_sg"
    }
}

resource "aws_security_group" "elk_server_sg" {
    name = "elk_server_sg"
    description = "Allow inbound traffic on port 22, 5044, 5601"
    vpc_id = aws_vpc.honey_net.id

    # Allow SSH traffic in
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow Logstash traffic in from honeypot_server_sg
    ingress {
        from_port   = 5044
        to_port     = 5044
        protocol    = "tcp"
        security_groups = [aws_security_group.honeypot_server_sg.id]
    }

    # Allow Kibana traffic in
    ingress {
        from_port   = 5601
        to_port     = 5601
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow all traffic out
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "elk_server_sg"
    }
}

resource "aws_instance" "elk_server" {
    availability_zone = "us-east-1a"
    subnet_id     = aws_subnet.honey_subnet.id
    security_groups = [aws_security_group.elk_server_sg.id]
    ami           = "ami-064519b8c76274859"
    instance_type = "t3.large"
    key_name      = "honey_net"
    associate_public_ip_address = true
    #user_data = file("${path.module}/elk_server_setup.sh")

    root_block_device {
        volume_size = 25
    }

    tags = {
        Name = "elk_server"
    }
}

resource "aws_instance" "honeypot_server" {
    availability_zone = "us-east-1a"
    subnet_id     = aws_subnet.honey_subnet.id
    security_groups = [aws_security_group.honeypot_server_sg.id]
    ami           = "ami-064519b8c76274859"
    instance_type = "t2.micro"
    key_name      = "honey_net"
    associate_public_ip_address = true
    #user_data = file("${path.module}/honeypot_server_setup.sh")

    root_block_device {
        volume_size = 8
    }

    tags = {
        Name = "honeypot_server"
    }
}