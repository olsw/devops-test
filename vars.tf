variable "AWS_REGION" {
    default = "eu-west-1"
}

variable "MY_IP" {
    default = "80.229.85.183/32"
}

variable "CANONICAL" {
    default = "099720109477"
}

variable "ssh_public_key" {
    default = "~/.ssh/devops-test.pub"
}

variable "ssh_private_key" {
    default = "~/.ssh/devops-test"
}

variable "aws_credentials_directory" {
    default = "/Users/olly/.aws"
}