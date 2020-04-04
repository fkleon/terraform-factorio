terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region  = var.region
  version = "~> 2.13"
}

provider "template" {
  version = "~> 2.1"
}

provider "tls" {
  version = "~> 2.1"
}

provider "null" {
  version = "~> 2.1"
}

locals {
  save_game_dir = "/opt/factorio/saves"
  # To load named save game: --start-server ${path}/${name}.zip
  # To load latest save game: --start-server-load-latest
  save_game_arg = (var.factorio_save_game != "" ?
    "--start-server ${local.save_game_dir}/${var.factorio_save_game}.zip'" :
  "--start-server-load-latest")
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "template_file" "cloud_config" {
  template = file("./cloud-config.yml")
  vars = {
    aws_region       = var.region
    ebs_device_path  = var.ebs_device_path
    factorio_version = var.factorio_version
  }
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
}

resource "aws_key_pair" "key" {
  key_name   = var.name
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "aws_default_vpc" "default" {
}

resource "aws_security_group" "instance" {
  vpc_id = aws_default_vpc.default.id
  name   = "${var.name}-security-group"
  tags   = var.tags

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol    = "udp"
    from_port   = 34197
    to_port     = 34197
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "factorio" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  associate_public_ip_address = true
  tags                        = var.tags

  root_block_device {
    volume_size           = 8
    volume_type           = "gp2"
    delete_on_termination = true
  }

  iam_instance_profile = var.instance_profile

  key_name        = aws_key_pair.key.key_name
  user_data       = data.template_file.cloud_config.rendered
  security_groups = [aws_security_group.instance.name]

  provisioner "file" {
    source      = "conf"
    destination = "/tmp"
  }

  provisioner "file" {
    content     = <<ENV
S3_BUCKET=${var.bucket_name}
SAVE_GAME_ARG=${local.save_game_arg}
ENV
    destination = "/tmp/factorio-environment"
  }

  # Initialise Factorio server settings, install systemd units.
  provisioner "remote-exec" {
    inline = [
      "sudo install -m 644 -o root -g root /tmp/factorio-environment -D -t /etc/factorio",
      "sudo install -m 644 -o root -g root /tmp/conf/server-settings.json /etc/factorio",
      "sudo install -m 644 -o root -g root /tmp/conf/server-adminlist.json /etc/factorio",
      "sudo install -m 644 -o root -g root /tmp/conf/factorio-headless.service /etc/systemd/system",
      "sudo install -m 644 -o root -g root /tmp/conf/factorio-backup.service /etc/systemd/system",
      "sudo install -m 644 -o root -g root /tmp/conf/factorio-restore.service /etc/systemd/system",
      "sudo systemctl daemon-reload",
    ]
  }

  connection {
    host        = self.public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
  }
}

resource "aws_ebs_volume" "factorio_data" {
  size              = 5
  availability_zone = aws_instance.factorio.availability_zone
}

resource "aws_volume_attachment" "factorio_mount" {
  # NVMe devices are always exposed as /dev/nvme<x>n1
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.factorio_data.id
  instance_id = aws_instance.factorio.id
}

resource "null_resource" "provision" {
  triggers = {
    instance_id            = aws_instance.factorio.id
    instance_ip            = aws_instance.factorio.public_ip
    private_key            = tls_private_key.ssh.private_key_pem
    data_volume_attachment = aws_volume_attachment.factorio_mount.volume_id
  }

  # Restore save games from S3 and start headless server.
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "sudo cloud-init status --wait > /dev/null 2>&1",
      "sudo systemctl start factorio-restore.service && sudo systemctl start factorio-headless.service",
    ]
  }

  # Stop headless server and backup save games to S3 on destroy.
  provisioner "remote-exec" {
    when = destroy
    inline = [
      "sudo systemctl stop factorio-headless.service",
      "sudo systemctl start factorio-backup.service",
      # Workaround for volume attachment timeout on destroy:
      # - https://github.com/terraform-providers/terraform-provider-aws/issues/1017
      # - https://github.com/terraform-providers/terraform-provider-aws/issues/4770
      "sudo umount /opt || true"
    ]
  }

  connection {
    host        = self.triggers.instance_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = self.triggers.private_key
  }
}
