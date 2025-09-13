data "aws_ami" "latest" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = ["vpn*"]
  }
}

resource "aws_instance" "vpn" {
  ami                    = data.aws_ami.latest.id
  instance_type          = "t3.medium"
  vpc_security_group_ids = [aws_security_group.vpn_security_group.id]
  subnet_id              = var.subnet_ip
  private_ip             = "10.0.2.4"
  key_name               = aws_key_pair.vpn_server_key.key_name
  iam_instance_profile   = aws_iam_instance_profile.vpn_instance_profile.name
}

resource "aws_security_group" "vpn_security_group" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Static ip
resource "aws_eip" "vpn" {
  vpc = true
}
resource "aws_eip_association" "vpn" {
  instance_id   = aws_instance.vpn.id
  allocation_id = aws_eip.vpn.id
}

# ssh key pair
resource "aws_key_pair" "vpn_server_key" {
  key_name   = "vpn"
  public_key = file("~/.ssh/aws_vpn.pub")
}

