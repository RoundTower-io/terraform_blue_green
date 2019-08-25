provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "b" {
  bucket = "${var.trainingID}-rtt-terraform-blue-green-example"
  acl    = "private"
}

data "archive_file" "bluezip" {
  type        = "zip"
  source_file = "${path.module}/blue/main.js"
  output_path = "${path.module}/blue.zip"
}

data "archive_file" "greenzip" {
  type        = "zip"
  source_file = "${path.module}/green/main.js"
  output_path = "${path.module}/green.zip"
}

resource "aws_s3_bucket_object" "blue" {
  bucket = aws_s3_bucket.b.id
  key    = "blue.zip"
  source = "./blue.zip"
}

resource "aws_s3_bucket_object" "green" {
  bucket = aws_s3_bucket.b.id
  key    = "green.zip"
  source = "./green.zip"
}

resource "aws_lambda_function" "example" {
  function_name = "${var.trainingID}_Blue_Green"

  # The bucket name as created earlier with "aws s3api create-bucket"
  s3_bucket = aws_s3_bucket.b.id
  s3_key    = "${var.deployment}.zip"

  # "main" is the filename within the zip file (main.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "main.handler"
  runtime = "nodejs10.x"

  role = "${aws_iam_role.lambda_exec.arn}"
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "lambda_exec" {
  name = "${var.trainingID}_bluegreen_example_lambda"

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

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.example.id}"
  parent_id   = "${aws_api_gateway_rest_api.example.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = "${aws_api_gateway_rest_api.example.id}"
  resource_id   = "${aws_api_gateway_resource.proxy.id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.example.arn}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_deployment.example.execution_arn}/*/*"
}