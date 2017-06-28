provider "aws" {
  region = "eu-west-1"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {
  current = true
}

# S3

resource "aws_s3_bucket" "jts" {
  bucket = "babbel-jts-test-user-data-2"
  acl    = "private"
}

resource "aws_s3_bucket_object" "user-data" {
	bucket  = "${aws_s3_bucket.jts.bucket}"
  key     = "authorized_keys"
  content = "${data.template_file.authorized_keys.rendered}"
}

# EC2

resource "aws_instance" "jts-user-data-test" {
  ami           = "ami-6d48500b",
  instance_type = "t2.micro"

  iam_instance_profile = "${aws_iam_instance_profile.jts-user-data-test.name}"

  user_data = "${data.template_file.user-data.rendered}"

  key_name = "jsaito"
}

resource "aws_iam_instance_profile" "jts-user-data-test" {
  name = "jts-user-data-bucket-reader"
  role = "${aws_iam_role.jts-user-data-test.name}"
}

# IAM

resource "aws_iam_role" "jts-user-data-test" {
  name = "user-data"

  assume_role_policy = "${data.aws_iam_policy_document.ec2-assume-role.json}"
}

data "aws_iam_policy_document" "ec2-assume-role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "jts-user-data-test-bucket" {
  statement {
    actions   = ["s3:List*","s3:Get*"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.jts.bucket}/*"]
  }
}

resource "aws_iam_role_policy" "jts-user-data-test-bucket-reader" {
  name = "user-data-test-bucket-reader"
  role = "${aws_iam_role.jts-user-data-test.id}"
  policy = "${data.aws_iam_policy_document.jts-user-data-test-bucket.json}"
}

# actual user data
data "template_file" "user-data" {
  template = "${file("user-data.sh")}"
}

# actual user data template
data "template_file" "authorized_keys" {
  template = "${file("authorized_keys")}"

  vars {
    tenmanya = "ssh-rsa ..."
  }
}
