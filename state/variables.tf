variable "region" {
  default = "eu-central-1"
}

variable "bucket_prefix" {
  default = "factorio-"
}

variable "tags" {
  type = map(string)
  default = {
    "Project" : "factorio"
  }
}
