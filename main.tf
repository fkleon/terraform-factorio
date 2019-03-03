variable "name" {}
variable "region" { default = "eu-central-1" }
variable "availability_zone" { default = "eu-central-1b" }
variable "tags" { type = "map", default = {} }
variable "instance_type" { default = "t2.micro" }
variable "ami" {
  # Ubuntu 18.04 Bionic LTS
  default = "ami-0bdf93799014acdc4"
}
variable "ebs_device_name" { default = "/dev/sdb" }
variable "ebs_device_name_int" { default = "/dev/xvdb" }
variable "vpc_id" {}
variable "ssh_key" {}
variable "ssh_private_key" {}
variable "factorio_version" { default = "0.16.51" }
variable "game_name" { default = "current" }

provider "aws" {
  region = "${var.region}"
}

resource "aws_key_pair" "key" {
  key_name = "${var.name}"
  public_key = "${var.ssh_key}"
}

resource "aws_security_group" "instance" {
  description = "Controls access to application instances"
  vpc_id = "${var.vpc_id}"
  name = "${var.name}-instance"
  tags = "${merge(map("Name", "${var.name}-instance"), var.tags)}"
  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol = "udp"
    from_port = 34197
    to_port = 34197
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/*
resource "aws_ebs_volume" "data" {
  size = 1
  type = "gp2"
  availability_zone = "${var.availability_zone}"
  tags = "${merge(map("Name", "${var.name}-ebs"), var.tags)}"
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdb"
  volume_id   = "${aws_ebs_volume.data.id}"
  instance_id = "${aws_instance.factorio.id}"
}
*/

data "template_file" "cloud_config" {
  template = "${file("./cloud-config.yml")}"
  vars {
    aws_region = "${var.region}"
    ebs_device_name = "${var.ebs_device_name_int}"
    factorio_version = "${var.factorio_version}"
    game_name = "${var.game_name}"
  }
}

resource "aws_eip" "ip" {
  instance = "${aws_instance.factorio.id}"
}

resource "aws_instance" "factorio" {
  ami           = "ami-0bdf93799014acdc4"
  instance_type = "${var.instance_type}"
  availability_zone = "${var.availability_zone}"

  root_block_device {
    volume_size = 8
    volume_type = "gp2"
    delete_on_termination = true 
  }

/*
  ebs_block_device {
    device_name = "${var.ebs_device_name}"
    volume_size = 1
    volume_type = "gp2"
    delete_on_termination = false 
  }
*/

  key_name      = "${aws_key_pair.key.key_name}"
  user_data     = "${data.template_file.cloud_config.rendered}"
  security_groups = ["${aws_security_group.instance.name}"]

  provisioner "file" {
    source      = "./conf/factorio-headless.service"
    destination = "/tmp/factorio-headless.service"
  }

  provisioner "file" {
    source      = "./conf/server-settings.json"
    destination = "/tmp/server-settings.json"
  }

  # XXX Use Puppet etc.?
  provisioner "remote-exec" {
    inline = [
      "sudo install -m 644 -o root -g root /tmp/server-settings.json -D -t /etc/factorio",
      "sudo install -m 644 -o root -g root /tmp/factorio-headless.service /etc/systemd/system",
      "sudo systemctl daemon-reload"
    ]
  }
  connection {
    type     = "ssh"
    user     = "ubuntu"
    private_key = "${var.ssh_private_key}"
  }
}

output "ip" {
  value = "${aws_eip.ip.public_ip}"
}
