provider "aws" {
    region = var.AWS_REGION
}

resource "aws_vpc" "devops-vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames    = "true"
}

resource "aws_subnet" "devops-subnet-public" {
    vpc_id                  = aws_vpc.devops-vpc.id
    cidr_block              = "10.0.1.0/24"
    map_public_ip_on_launch = "true"
}

resource "aws_internet_gateway" "devops-igw" {
    vpc_id = aws_vpc.devops-vpc.id
}

resource "aws_route_table" "devops-route-public" {
    vpc_id = aws_vpc.devops-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.devops-igw.id
    }
}

resource "aws_route_table_association" "devops-route-subnet-public" {
    subnet_id      = aws_subnet.devops-subnet-public.id
    route_table_id = aws_route_table.devops-route-public.id
}

resource "aws_security_group" "devops-access" {
    vpc_id = aws_vpc.devops-vpc.id


    egress {
        from_port   = 0
        to_port     = 0
        protocol    = -1
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port        = 22
        to_port          = 22
        protocol         = "tcp"
        cidr_blocks      = var.GitHubIP
        ipv6_cidr_blocks = var.GitHubIPv6
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 3000
        to_port   = 3000
        protocol  = "tcp"
        self      = true
    }

}