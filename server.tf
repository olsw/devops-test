
resource "aws_key_pair" "devops-test" {
    key_name   = "devops-test"
    public_key = file(var.ssh_public_key)
}

data "aws_ami" "ubuntu-latest" {
    most_recent = true

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

    owners = [var.CANONICAL]
}

resource "aws_instance" "app-servers" {
    //Create two application servers
    ami                    = data.aws_ami.ubuntu-latest.id
    count                  = 2
    instance_type          = "t2.micro"
    key_name               = aws_key_pair.devops-test.key_name

    subnet_id              = aws_subnet.devops-subnet-public.id
    vpc_security_group_ids = [aws_security_group.devops-access.id]

    // Install docker, docker-compose and aws-cli using the best prescribed methods
    // Optionally could bake this into a base image
    connection {
        type        = "ssh"
        host        = self.public_ip
        user        = "ubuntu"
        private_key = file(var.ssh_private_key)
    }

    provisioner "file" {
        // Due to a bug with terraform (https://github.com/hashicorp/terraform/issues/16330)
        // it is easier to copy the whole directory rather than the single credentials file we need
        source      = var.aws_credentials_directory
        destination = "/home/ubuntu/.aws"

    }

    provisioner "remote-exec" {
        // Install docker and docker-compose on the boxes
        inline = [
            "sudo apt-get update",
            "sudo apt install -y apt-transport-https ca-certificates curl software-properties-common",
            "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
            "sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable'",
            "sudo apt-get update",
            "sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable'",
            "sudo apt-get update",
            "sudo apt install -y docker-ce",
            "sudo curl -L \"https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
            "sudo chmod +x /usr/local/bin/docker-compose",
            "sudo apt install -y awscli",
            "aws ecr get-login-password --region eu-west-1 | sudo docker login --username AWS --password-stdin 343116501882.dkr.ecr.eu-west-1.amazonaws.com"
        ]
    }
}

resource "aws_elb" "app-servers-elb" {
    // Create the load balancer for the two app servers
    listener {
        instance_port     = 3000
        instance_protocol = "http"
        lb_port           = 80
        lb_protocol       = "http"
    }

    health_check {
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 3
        target              = "HTTP:3000/"
        interval            = 30
    }

    subnets         = [aws_subnet.devops-subnet-public.id]
    instances       = aws_instance.app-servers.*.id
    security_groups = [aws_security_group.devops-access.id]
}

output "instance_dns" {
    value = aws_instance.app-servers.*.public_dns
}

output "load-balancer-address" {
    value = aws_elb.app-servers-elb.dns_name
}