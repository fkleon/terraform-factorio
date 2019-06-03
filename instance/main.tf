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
    ebs_device_name  = var.ebs_device_name_int
    factorio_version = var.factorio_version
  }
}

resource "aws_key_pair" "key" {
  key_name   = var.name
  public_key = var.ssh_public_key
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

/*
resource "aws_eip" "ip" {
  instance = aws_instance.factorio.id
}
*/

resource "aws_instance" "factorio" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  availability_zone           = var.availability_zone
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
    content     = "S3_BUCKET=${var.bucket_name}"
    destination = "/tmp/factorio-environment"
  }

  # Initialise Factorio server settings, install systemd units.
  provisioner "remote-exec" {
    inline = [
      "sudo install -m 644 -o root -g root /tmp/factorio-environment -D -t /etc/factorio",
      "sudo install -m 644 -o root -g root /tmp/conf/server-settings.json /etc/factorio",
      "sudo install -m 644 -o root -g root /tmp/conf/factorio-headless.service /etc/systemd/system",
      "sudo install -m 644 -o root -g root /tmp/conf/factorio-backup.service /etc/systemd/system",
      "sudo install -m 644 -o root -g root /tmp/conf/factorio-restore.service /etc/systemd/system",
      "sudo systemctl daemon-reload",
    ]
  }

  # Restore save games from S3 and start headless server.
  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait",
      "sudo systemctl start factorio-restore.service && sudo systemctl start factorio-headless.service",
    ]
  }

  # Stop headless server and backup save games to S3 on destroy.
  provisioner "remote-exec" {
    when = "destroy"
    inline = [
      "sudo systemctl stop factorio-headless.service",
      "sudo systemctl start factorio-backup.service",
    ]
  }

  connection {
    host        = coalesce(self.public_ip, self.private_ip)
    type        = "ssh"
    user        = "ubuntu"
    private_key = var.ssh_private_key
  }
}
