packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.4"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "vpn" {
  ami_name             = "vpn-{{timestamp}}"
  instance_type        = "t3.medium"
  region               = "eu-west-2"
  ssh_username         = "root"
  iam_instance_profile = "vpn-instance-profile"

  source_ami_filter {
    filters = {
      architecture = "x86_64"
    }
    most_recent = true
    owners      = ["427812963091"]
  }

  launch_block_device_mappings {
    device_name = "/dev/xvda"
    volume_size = 30
    volume_type = "gp3"
  }
}

# For some reason we have to run this on startup
# sudo systemctl start wireguard-wg0 

build {
  sources = ["source.amazon-ebs.vpn"]

  provisioner "file" {
    source      = "services/vpn/configuration.nix"
    destination = "/tmp/configuration.nix"
  }

  provisioner "shell" {
    inline = [
      "mv /tmp/configuration.nix /etc/nixos/configuration.nix",
      "nixos-rebuild switch --upgrade",
      "nix-collect-garbage -d",
      "rm -rf /etc/ec2-metadata /etc/ssh/ssh_host_* /root/.ssh" # Or you can't ssh i think
    ]
  }
}
