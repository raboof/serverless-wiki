# Provide your credentials as environment variables:
# $ export AWS_ACCOUNT_ID="accountid"
# $ export AWS_ACCESS_KEY_ID="anaccesskey"
# $ export AWS_SECRET_ACCESS_KEY="asecretkey"
# $ export AWS_DEFAULT_REGION="us-west-2"
# $ terraform plan
provider "aws" { }

variable "aws_region" {
  default = "eu-west-1"
}
