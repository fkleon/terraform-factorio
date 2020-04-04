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

variable "ebs_device_path" {
  type        = string
  default     = "/dev/xvdf"
  description = "Internal EBS device name to use for Factorio data."
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
  default     = "latest"
  description = "Version of Factorio to install on the server."
}

variable "factorio_save_game" {
  type        = string
  default     = ""
  description = "Name of the Factorio save game to load. Leave empty to load latest save game."
}
