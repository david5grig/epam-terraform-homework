terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.37.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  #  shared_credentials_file = "/home/david/Downloads/credentials"
  profile = "default"
}

resource "aws_security_group" "allow_http_https_ssh" {
  name        = "allow_http_https_ssh"
  description = "Allow http, https & ssh inbound traffic"
  vpc_id      = "vpc-7e03bc03"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "my_ec2" {
  ami                    = "ami-042e8287309f5df03"
  instance_type          = "t2.micro"
  key_name               = "aws-demo"
  vpc_security_group_ids = ["${aws_security_group.allow_http_https_ssh.id}"]
  subnet_id              = "subnet-0ec6d6da131536c62"
  associate_public_ip_address = true
}

#resource "aws_eip" "byoip-ip" {
#  vpc              = true
#  public_ipv4_pool = "ipv4pool-ec2-012345"
#}

resource "local_file" "inventory" {
  content = templatefile("inventory.tmpl",
    {
      public_ip = aws_instance.my_ec2.public_ip
    }
  )
  filename = "inventory"
}

resource "null_resource" "runansible" {
provisioner "local-exec" {
  command = "ansible-playbook -i hosts tasks.yml"

	}	
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.my_ec2.public_ip
}
