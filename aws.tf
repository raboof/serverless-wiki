# Provide your credentials as environment variables:
# $ export AWS_ACCESS_KEY_ID="anaccesskey"
# $ export AWS_SECRET_ACCESS_KEY="asecretkey"
# $ export AWS_DEFAULT_REGION="us-west-2"
# $ terraform plan
provider "aws" { }

resource "aws_s3_bucket" "serverless-wiki" {
  # TODO make bucket name configurable (as they're global)
  bucket = "serverless-wiki"
  acl = "public-read"
  policy = <<POLICY
{
  "Version":"2012-10-17",
  "Statement":[{
	"Sid":"PublicReadGetObject",
        "Effect":"Allow",
	  "Principal": "*",
      "Action":["s3:GetObject"],
      "Resource":["arn:aws:s3:::serverless-wiki/*"
      ]
    }
  ]
}
POLICY
  website {
    index_document = "index.html"
  }
}

resource "aws_iam_user" "serverless-wiki" {
  name = "serverless-wiki"
}

resource "aws_iam_access_key" "serverless-wiki" {
  user = "${aws_iam_user.serverless-wiki.name}"
}

resource "aws_iam_user_policy" "serverless-wiki-update-files" {
  name = "test"
  user = "${aws_iam_user.serverless-wiki.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.serverless-wiki.bucket}",
        "arn:aws:s3:::${aws_s3_bucket.serverless-wiki.bucket}/*"
      ]
    }
  ]
}
EOF
}


output "secret" {
  value = "${aws_iam_access_key.serverless-wiki.encrypted_secret}"
}
