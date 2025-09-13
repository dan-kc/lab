terraform {
  required_version = ">= 1.8.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  backend "s3" {
    bucket         = "lab-terraform-state-gftwdav7m4r4f5z1y0c7tqfcmf"
    key            = "terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true
    dynamodb_table = "lab-terraform-state-lock-zheym3vydygj126xyvujbddntb"
  }
}

provider "aws" {
  region = "eu-west-2"
}

resource "aws_ecs_cluster" "lab" {
  name = "ecs-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

module "vpn" {
  source                      = "./services/vpn"
  subnet_ip                   = aws_subnet.public.id
  vpc_id                      = aws_vpc.lab.id
}

module "jellyfin" {
  source                      = "./services/jellyfin"
  subnet_ip                   = aws_subnet.private.id
  vpc_id                      = aws_vpc.lab.id
}
