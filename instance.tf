resource "aws_key_pair" "first-key" {
  key_name   = "first-key"
  public_key = file("${path.module}/id_rsa.pub")
}

output "keyname" {
  value = aws_key_pair.first-key.key_name
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.first-key.key_name
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  tags = {
    Name = "First aws instance"
  }
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"

  dynamic "ingress" {
    for_each = [22, 80, 443, 8000]
    iterator = port
    content {
      description = "TLS from VPC"
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

output "SecurityGroupDetails" {
  value = aws_security_group.allow_tls.id
}

# resource "aws_s3_bucket" "example" {
#   bucket = "my-tf-test-bucket"

#   tags = {
#     Name        = "My bucket"
#     Environment = "Dev"
#   }
# }

output "instance_public_ip" {
  value = aws_instance.web.public_ip
}
