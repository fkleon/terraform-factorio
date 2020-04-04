terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region  = var.region
  version = "~> 2.13"
}

resource "aws_s3_bucket" "backup" {
  bucket_prefix = var.bucket_prefix
  acl           = "private"
  tags          = var.tags

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "old-saves"
    enabled = true

    prefix = "saves/"

    noncurrent_version_expiration {
      days = 180
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_policy" "backup" {
  bucket = aws_s3_bucket.backup.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_role.backup.arn}"
      },
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": "${aws_s3_bucket.backup.arn}"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_role.backup.arn}"
      },
      "Action": [
        "s3:GetObject",
        "s3:GetObjectTagging",
        "s3:GetObjectVersion",
        "s3:GetObjectVersionTagging",
        "s3:PutObject",
        "s3:PutObjectTagging",
        "s3:PutObjectVersionTagging"
      ],
      "Resource": "${aws_s3_bucket.backup.arn}/*"
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "backup" {
  name = "factorio-iam-role-policy-backup"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "s3:*",
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.backup.arn}",
        "${aws_s3_bucket.backup.arn}/*"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_role" "backup" {
  name = "factorio-iam-role-backup"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = aws_iam_policy.backup.arn
}

resource "aws_iam_instance_profile" "backup" {
  name = "factorio-instance-profile"
  role = aws_iam_role.backup.name
}
