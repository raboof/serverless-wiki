variable "aws_account_id" { }
variable "source_git_url" { }
variable "nonce" { }

resource "aws_iam_policy" "s3_write_access" {
  name = "s3_write_access"
  path = "/"
  description = "IAM policy for s3 write access"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::serverless-wiki/*"
      ],
      "Effect": "Allow"
    },
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_writes_s3" {
  role = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "${aws_iam_policy.s3_write_access.arn}"
}

resource "aws_lambda_function" "serverless-edit" {
  filename = "serverless-wiki-lambda.zip"
  function_name = "edit"
  role = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "edit.hello"
  source_code_hash = "${base64sha256(file("serverless-wiki-lambda.zip"))}"
  runtime = "python2.7"
  timeout = 20

  environment {
    variables = {
      SOURCE_GIT_URL = "${var.source_git_url}"
      NONCE = "${var.nonce}"
    }
  }
}

resource "aws_api_gateway_rest_api" "serverless-wiki-api" {
  name = "serverless-wiki-api"
  description = "API for the 'active' parts of the serverless-wiki"
}

resource "aws_api_gateway_resource" "serverless-edit" {
  rest_api_id = "${aws_api_gateway_rest_api.serverless-wiki-api.id}"
  parent_id = "${aws_api_gateway_rest_api.serverless-wiki-api.root_resource_id}"
  path_part = "edit"
}

resource "aws_api_gateway_method" "submit" {
  rest_api_id = "${aws_api_gateway_rest_api.serverless-wiki-api.id}"
  resource_id = "${aws_api_gateway_resource.serverless-edit.id}"
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id = "${aws_api_gateway_rest_api.serverless-wiki-api.id}"
  resource_id = "${aws_api_gateway_resource.serverless-edit.id}"
  http_method = "${aws_api_gateway_method.submit.http_method}"
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.serverless-edit.arn}/invocations"
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.serverless-edit.arn}"
  principal = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.aws_region}:${var.aws_account_id}:${aws_api_gateway_rest_api.serverless-wiki-api.id}/*/${aws_api_gateway_method.submit.http_method}${aws_api_gateway_resource.serverless-edit.path}"
}

#resource "aws_api_gateway_stage" "prod" {
#  stage_name = "sw_prod"
#  rest_api_id = "${aws_api_gateway_rest_api.serverless-wiki-api.id}"
#  deployment_id = "${aws_api_gateway_deployment.prod.id}"
#}

resource "aws_api_gateway_deployment" "prod" {
  depends_on = ["aws_api_gateway_integration.integration"]
  rest_api_id = "${aws_api_gateway_rest_api.serverless-wiki-api.id}"
  stage_name = "sw_prod"
}

resource "aws_api_gateway_method_settings" "s" {
  rest_api_id = "${aws_api_gateway_rest_api.serverless-wiki-api.id}"
  stage_name = "${aws_api_gateway_deployment.prod.stage_name}"
  method_path = "${aws_api_gateway_resource.serverless-edit.path_part}/${aws_api_gateway_method.submit.http_method}"
  settings {
    metrics_enabled = true
    # logging_level = "INFO"
  }
}

resource "aws_api_gateway_method_response" "200" {
  rest_api_id = "${aws_api_gateway_rest_api.serverless-wiki-api.id}"
  resource_id = "${aws_api_gateway_resource.serverless-edit.id}"
  http_method = "${aws_api_gateway_method.submit.http_method}"
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "integration_response" {
  rest_api_id = "${aws_api_gateway_rest_api.serverless-wiki-api.id}"
  resource_id = "${aws_api_gateway_resource.serverless-edit.id}"
  http_method = "${aws_api_gateway_method.submit.http_method}"
  status_code = "${aws_api_gateway_method_response.200.status_code}"
}
