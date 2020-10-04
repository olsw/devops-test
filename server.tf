
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
    ami                    = data.aws_ami.ubuntu-latest.id
    count                  = 2
    instance_type          = "t2.micro"
    key_name               = aws_key_pair.devops-test.key_name

    subnet_id              = aws_subnet.devops-subnet-public.id
    vpc_security_group_ids = [aws_security_group.devops-access.id]

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
            "sudo chmod +x /usr/local/bin/docker-compose"
        ]
        connection {
            type        = "ssh"
            host        = self.public_ip
            user        = "ubuntu"
            private_key = file(var.ssh_private_key)
        }
    }
}

resource "aws_elb" "app-servers-elb" {
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

    subnets   = [aws_subnet.devops-subnet-public.id]
    instances = aws_instance.app-servers.*.id
}

output "instance_ids" {
    value = aws_instance.app-servers.*.id
}