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
	bucket = "${aws_s3_bucket.jts.bucket}"
  key    = "authorized_keys"
  source = "create-users.yml"
  acl    = "public-read"
}

# EC2

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "jts-user-data-test" {
  ami           = "ami-6d48500b",
  instance_type = "t2.micro"

  iam_instance_profile = "${aws_iam_instance_profile.jts-user-data-test.name}"

  user_data = "${data.template_file.user-data.rendered}"

  key_name = "jsaito"

  security_groups = ["allow_all"]
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

# actual user data
data "template_file" "user-data" {
  template = "#include\n$${url}"

  vars = {
		url = "https://s3-eu-west-1.amazonaws.com/babbel-jts-test-user-data-2/authorized_keys"
  }
}
