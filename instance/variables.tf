variable "name" {
  type        = string
  default     = "factorio"
  description = "Prefix to use for resource names."
}

variable "region" {
  type        = string
  default     = "eu-central-1"
  description = "AWS region to create resources in."
}

variable "availability_zone" {
  type        = string
  default     = "eu-central-1b"
  description = "AWS availablility zone to create resources in."
}

variable "tags" {
  type = map(string)
  default = {
    "Project" : "factorio"
  }
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
  description = "AWS instance type to use for the Factorio server."
}

/*
variable "ebs_device_name" {
  type    = string
  default = "/dev/sdb"
  description = "EBS device name to use for Factorio."
}
*/

variable "ebs_device_name_int" {
  type        = string
  default     = "/dev/xvdb"
  description = "Internal EBS device name to use for Factorio data."
}

variable "ssh_public_key" {
  type        = string
  description = "SSH key to provision into authorized_keys."
}

variable "ssh_private_key" {
  type        = string
  description = "SSH private key to use for file provisioning."
}

variable "bucket_name" {
  type        = string
  description = "S3 bucket to use for save game backups."
}

variable "instance_profile" {
  type        = string
  default     = "factorio-instance-profile"
  description = "Instance profile to assign to AWS instance. This should be configured to allow access to the S3 backup bucket."
}

variable "factorio_version" {
  type        = string
  default     = "0.17.45"
  description = "Version of Factorio to install on the server."
}