data "aws_ami" "latest" {
  most_recent = true
  owners = ["self"]
  filter {
    name   = "name"
    values = ["jellyfin*"]
  }
}

resource "aws_instance" "jellyfin" {
  ami                    = data.aws_ami.latest.id
  instance_type          = "t3.medium"
  vpc_security_group_ids = [aws_security_group.jellyfin_security_group.id]
  subnet_id              = var.subnet_ip
  private_ip             = "10.0.1.4"
  key_name               = aws_key_pair.jellyfin_server_key.key_name
  iam_instance_profile   = aws_iam_instance_profile.jellyfin_instance_profile.name
}

resource "aws_security_group" "jellyfin_security_group" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.2.4/32"]
  }

  ingress {
    from_port   = 8096
    to_port     = 8096
    protocol    = "tcp"
    cidr_blocks = ["10.0.2.4/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ssh key pair
resource "aws_key_pair" "jellyfin_server_key" {
  key_name   = "jellyfin"
  public_key = file("~/.ssh/aws_jellyfin.pub")
}

