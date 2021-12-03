terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region  = "eu-central-1"
  profile = "default"
}

variable "ingressrules" {
  type    = list(number)
  default = [80, 8080, 443, 22]
}

resource "aws_security_group" "web_traffic" {
  name = "Allow web traffic"

  dynamic "ingress" {
    iterator = port
    for_each = var.ingressrules
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Terraform" = "true"
  }
}

resource "aws_instance" "jenkins_master" {
  ami             = "ami-0a49b025fffbbdac6"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.web_traffic.name]
  key_name        = "radon"

  tags = {
    Name      = "JenkinsMaster"
    Terraform = "true"
  }
}

resource "aws_instance" "deploy" {
  ami             = "ami-0a49b025fffbbdac6"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.web_traffic.name]
  key_name        = "radon"

  tags = {
    Name      = "Deploy"
    Terraform = "true"
  }
}

resource "local_file" "ansible_inventory" {
  content = templatefile("inventory.tmpl",
    {
      jenkins_master = aws_instance.jenkins_master.*.public_ip
      deploy         = aws_instance.deploy.*.public_ip
    }
  )
  filename = "inventory"
}

resource "local_file" "deploy_server_ip" {
  content = templatefile("deploy_server_ip.tmpl",
    {
      ip_list = aws_instance.deploy.*.public_ip
    }
  )
  filename = "deploy_server_ip"
}
