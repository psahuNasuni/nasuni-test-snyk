locals {
  lambda_code_files              = "SearchUI"
  lambda_code_file_name_SearchUI = "Search_UI_lambda"
  lambda_code_file_name_NMC_VOL  = "get_volume_names"
  lambda_folder                  = "Search_UI_lambda"
  lambda_code_extension          = ".py"
  handler                        = "lambda_handler"
  resource_name_prefix           = "nasuni-labs"
  stage_name                     = var.stage_name
  api_type                       = var.use_private_ip != "Y" ? "REGIONAL" : "PRIVATE"
}

resource "random_id" "unique_SearchUI_id" {
  byte_length = 2
}

data "aws_caller_identity" "current" {}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${local.lambda_folder}/"
  output_path = "${local.lambda_code_files}.zip"
}
################### START - Search_UI_lambda Lambda ####################################################

data "aws_security_groups" "es" {
  filter {
    name   = "vpc-id"
    values = [var.user_vpc_id]
  }
}
resource "aws_lambda_function" "lambda_function_search_es" {
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "${local.lambda_code_file_name_SearchUI}.${local.handler}"
  runtime       = var.runtime
  filename      = "${local.lambda_code_files}.zip"
  function_name = "${local.resource_name_prefix}-${local.lambda_code_file_name_SearchUI}-${random_id.unique_SearchUI_id.dec}"

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 20
  vpc_config {
    security_group_ids = [data.aws_security_groups.es.ids[0]]
    subnet_ids         = [var.user_subnet_id]
  }
  tags = {
    Name            = "${local.resource_name_prefix}-${local.lambda_code_file_name_SearchUI}-${random_id.unique_SearchUI_id.dec}"
    Application     = "Nasuni Analytics Connector with Elasticsearch"
    Developer       = "Nasuni"
    PublicationType = "Nasuni Labs"
    Version         = "V 0.1"
  }
  depends_on = [
    aws_iam_role_policy_attachment.lambda_logging,
    aws_iam_role_policy_attachment.ESHttpPost_access,
    aws_iam_role_policy_attachment.GetSecretValue_access,
    aws_cloudwatch_log_group.lambda_log_group_search
  ]

}
################### END - Search_UI_lambda Lambda ####################################################

################### START - Get ES Volumes Lambda ####################################################

resource "aws_lambda_function" "lambda_function_get_es_volumes" {
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "${local.lambda_code_file_name_NMC_VOL}.${local.handler}"
  runtime          = var.runtime
  filename         = "${local.lambda_code_files}.zip"
  function_name    = "${local.resource_name_prefix}-${local.lambda_code_file_name_NMC_VOL}-${random_id.unique_SearchUI_id.dec}"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 20
  vpc_config {
    security_group_ids = [data.aws_security_groups.es.ids[0]]
    subnet_ids         = [var.user_subnet_id]
  }
  tags = {
    Name            = "${local.resource_name_prefix}-${local.lambda_code_file_name_NMC_VOL}-${random_id.unique_SearchUI_id.dec}"
    Application     = "Nasuni Analytics Connector with Elasticsearch"
    Developer       = "Nasuni"
    PublicationType = "Nasuni Labs"
    Version         = "V 0.1"
  }
  depends_on = [
    aws_iam_role_policy_attachment.lambda_logging,
    aws_iam_role_policy_attachment.ESHttpPost_access,
    aws_iam_role_policy_attachment.GetSecretValue_access,
    aws_cloudwatch_log_group.lambda_log_group_volume
  ]

}
################### END - Get ES Volumes Lambda ####################################################

################### START - Lambda Role and Policies  ####################################################

resource "aws_iam_role" "lambda_exec_role" {
  name        = "${local.resource_name_prefix}-exec_role-${local.lambda_code_files}-${random_id.unique_SearchUI_id.dec}"
  path        = "/"
  description = "Allows Lambda Function to call AWS services on your behalf."

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = {
    Name            = "${local.resource_name_prefix}-exec-${local.lambda_code_files}-${random_id.unique_SearchUI_id.dec}"
    Application     = "Nasuni Analytics Connector with Elasticsearch"
    Developer       = "Nasuni"
    PublicationType = "Nasuni Labs"
    Version         = "V 0.1"
  }
}

############## CloudWatch Integration for Search Lambda ######################
resource "aws_cloudwatch_log_group" "lambda_log_group_search" {
  name              = "/aws/lambda/${local.resource_name_prefix}-${local.lambda_code_file_name_SearchUI}-${random_id.unique_SearchUI_id.dec}"
  retention_in_days = 14

  tags = {
    Name            = "${local.resource_name_prefix}-lambda_log_group-${local.lambda_code_file_name_SearchUI}-${random_id.unique_SearchUI_id.dec}"
    Application     = "Nasuni Analytics Connector with Elasticsearch"
    Developer       = "Nasuni"
    PublicationType = "Nasuni Labs"
    Version         = "V 0.1"
  }
}

############## CloudWatch Integration for Volume Lambda ######################
resource "aws_cloudwatch_log_group" "lambda_log_group_volume" {
  name              = "/aws/lambda/${local.resource_name_prefix}-${local.lambda_code_file_name_NMC_VOL}-${random_id.unique_SearchUI_id.dec}"
  retention_in_days = 14

  tags = {
    Name            = "${local.resource_name_prefix}-lambda_log_group-${local.lambda_code_file_name_NMC_VOL}-${random_id.unique_SearchUI_id.dec}"
    Application     = "Nasuni Analytics Connector with Elasticsearch"
    Developer       = "Nasuni"
    PublicationType = "Nasuni Labs"
    Version         = "V 0.1"
  }
}


# AWS Lambda Basic Execution Role
resource "aws_iam_policy" "lambda_logging" {
  name        = "${local.resource_name_prefix}-lambda_logging_policy-${local.lambda_code_files}-${random_id.unique_SearchUI_id.dec}"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
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
  tags = {
    Name            = "${local.resource_name_prefix}-lambda_logging_policy-${local.lambda_code_files}-${random_id.unique_SearchUI_id.dec}"
    Application     = "Nasuni Analytics Connector with Elasticsearch"
    Developer       = "Nasuni"
    PublicationType = "Nasuni Labs"
    Version         = "V 0.1"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_logging" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}


############## IAM policy for accessing ElasticSearch Domain from a lambda ######################
resource "aws_iam_policy" "ESHttpPost_access" {
  name        = "${local.resource_name_prefix}-ESHttpPost_access_policy-${local.lambda_code_files}-${random_id.unique_SearchUI_id.dec}"
  path        = "/"
  description = "IAM policy for accessing ElasticSearch Domain from a lambda"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "es:ESHttpPost"
            ],
            "Resource": "*"
        }
    ]
}
EOF
  tags = {
    Name            = "${local.resource_name_prefix}-ESHttpPost_access_policy-${local.lambda_code_files}-${random_id.unique_SearchUI_id.dec}"
    Application     = "Nasuni Analytics Connector with Elasticsearch"
    Developer       = "Nasuni"
    PublicationType = "Nasuni Labs"
    Version         = "V 0.1"
  }
}

resource "aws_iam_role_policy_attachment" "ESHttpPost_access" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.ESHttpPost_access.arn
}

############## IAM policy for accessing Secret Manager from a lambda ######################
resource "aws_iam_policy" "GetSecretValue_access" {
  name        = "${local.resource_name_prefix}-GetSecretValue_access_policy-${local.lambda_code_files}-${random_id.unique_SearchUI_id.dec}"
  path        = "/"
  description = "IAM policy for accessing secretmanager from a lambda"


  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": "${data.aws_secretsmanager_secret.admin_secret.arn}"
        }
    ]
}
EOF
  tags = {
    Name            = "${local.resource_name_prefix}-GetSecretValue_access_policy-${local.lambda_code_files}-${random_id.unique_SearchUI_id.dec}"
    Application     = "Nasuni Analytics Connector with Elasticsearch"
    Developer       = "Nasuni"
    PublicationType = "Nasuni Labs"
    Version         = "V 0.1"
  }
}

resource "aws_iam_role_policy_attachment" "GetSecretValue_access" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.GetSecretValue_access.arn
}

data "aws_secretsmanager_secret" "admin_secret" {
  name = var.admin_secret
}
data "aws_secretsmanager_secret_version" "admin_secret" {
  secret_id = data.aws_secretsmanager_secret.admin_secret.id
}

data "aws_iam_policy" "CloudWatchFullAccess" {
  arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_iam_role_policy_attachment" "CloudWatchFullAccess" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = data.aws_iam_policy.CloudWatchFullAccess.arn
}

data "aws_iam_policy" "AmazonESFullAccess" {

  arn = "arn:aws:iam::aws:policy/AmazonESFullAccess"
}

resource "aws_iam_role_policy_attachment" "AmazonESFullAccess" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = data.aws_iam_policy.AmazonESFullAccess.arn
}


data "aws_iam_policy" "AmazonOpenSearchServiceFullAccess" {
  arn = "arn:aws:iam::aws:policy/AmazonOpenSearchServiceFullAccess"
}

resource "aws_iam_role_policy_attachment" "AmazonOpenSearchServiceFullAccess" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = data.aws_iam_policy.AmazonOpenSearchServiceFullAccess.arn
}

data "aws_iam_policy" "AmazonOpenSearchServiceReadOnlyAccess" {
  arn = "arn:aws:iam::aws:policy/AmazonOpenSearchServiceReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "AmazonOpenSearchServiceReadOnlyAccess" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = data.aws_iam_policy.AmazonOpenSearchServiceReadOnlyAccess.arn
}
data "aws_iam_policy" "AWSLambdaVPCAccessExecutionRole" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "AWSLambdaVPCAccessExecutionRole" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = data.aws_iam_policy.AWSLambdaVPCAccessExecutionRole.arn
}

################### END - Lambda Role and Policies  ####################################################


################### START - API Gateway setup for Get Volume Lambda and Search ES Lambda ####################################################

data "aws_vpc_endpoint_service" "vpc-endpoint-service" {
  service = "execute-api"
}

resource "aws_vpc_endpoint_service" "vpc-endpoint-service" {
  count               = null == data.aws_vpc_endpoint_service.vpc-endpoint-service.service_id ? 1 : 0
  acceptance_required = true
  depends_on = [
    data.aws_vpc_endpoint_service.vpc-endpoint-service
  ]
}

resource "aws_vpc_endpoint" "SearchES-API-vpc-endpoint" {
  # count               = "Y" == var.use_private_ip ? 1 : 0
  count               = "Y" == var.use_private_ip  && "" == var.vpc_endpoint_id ? 1 : 0
  vpc_id              = var.user_vpc_id
  service_name        = data.aws_vpc_endpoint_service.vpc-endpoint-service.service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [data.aws_security_groups.es.ids[0]]
  subnet_ids          = [var.user_subnet_id]
  tags = {
    Name            = "${local.resource_name_prefix}-vpc_endpoint"
    Application     = "Nasuni Analytics Connector with Elasticsearch"
    Developer       = "Nasuni"
    PublicationType = "Nasuni Labs"
    Version         = "V 0.1"
  }
}

locals {
  vpc_endpoint_id   = var.vpc_endpoint_id == "" ? aws_vpc_endpoint.SearchES-API-vpc-endpoint[0].id : var.vpc_endpoint_id
}

resource "aws_api_gateway_rest_api_policy" "SearchES-API-policy" {
  rest_api_id = aws_api_gateway_rest_api.SearchES-API.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": "execute-api:Invoke",
            "Resource": [
              "execute-api:/*"
            ]
        },
        {
            "Effect": "Deny",
            "Principal": "*",
            "Action": "execute-api:Invoke",
            "Resource": [
              "execute-api:/*"
            ],
            "Condition" : {
                "StringNotEquals": {
                    "aws:SourceVpc": "${tostring(var.user_vpc_id)}"
                }
            }
        }
    ]
}
EOF
}


### Creating Rest API gateway
resource "aws_api_gateway_rest_api" "SearchES-API" {
  name        = "${local.resource_name_prefix}-${local.lambda_code_files}-${random_id.unique_SearchUI_id.dec}"
  description = "API created for exposing Lambda Functions for fetching Volumes and Search ES Data"
  endpoint_configuration {
    types            = [local.api_type]
    vpc_endpoint_ids = [var.use_private_ip != "Y" ? null : local.vpc_endpoint_id]
    # vpc_endpoint_ids = [var.use_private_ip != "Y" ? null : aws_vpc_endpoint.SearchES-API-vpc-endpoint[0].id]
  }

  depends_on = [
    aws_lambda_function.lambda_function_get_es_volumes,
    aws_lambda_function.lambda_function_search_es
  ]
}
################### START - API Gateway setup for Get Volume Lambda ####################################################

### Creating Resource for Rest API Gateway created
resource "aws_api_gateway_resource" "APIresourceForVolumeFetch" {

  path_part   = "es-volume"
  parent_id   = aws_api_gateway_rest_api.SearchES-API.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.SearchES-API.id
  depends_on = [
    aws_api_gateway_rest_api.SearchES-API
  ]
}

### Creating Method for API Gateway Created
resource "aws_api_gateway_method" "APImethodForLambdaFunction" {
  rest_api_id   = aws_api_gateway_rest_api.SearchES-API.id
  resource_id   = aws_api_gateway_resource.APIresourceForVolumeFetch.id
  http_method   = "GET"
  authorization = "NONE"
  depends_on = [
    aws_api_gateway_resource.APIresourceForVolumeFetch
  ]
}

### Integrating the API Gateway with the Lambda function to deploy
resource "aws_api_gateway_integration" "IntegratingLambdaFunctionWithAPIgateway" {
  rest_api_id             = aws_api_gateway_rest_api.SearchES-API.id
  resource_id             = aws_api_gateway_resource.APIresourceForVolumeFetch.id
  http_method             = aws_api_gateway_method.APImethodForLambdaFunction.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.lambda_function_get_es_volumes.arn}/invocations"

  request_templates = {
    "application/json" = jsonencode(
      {
        statusCode = 200
      }
    )
  }
  depends_on = [
    aws_api_gateway_rest_api.SearchES-API,
    aws_api_gateway_resource.APIresourceForVolumeFetch,
    aws_api_gateway_method.APImethodForLambdaFunction
  ]

}



### Specifying integration response of the lambda function with the API gateway for fetching volume
resource "aws_api_gateway_integration_response" "APIintegrationResponseOfLambdafunction" {
  rest_api_id = aws_api_gateway_rest_api.SearchES-API.id
  resource_id = aws_api_gateway_resource.APIresourceForVolumeFetch.id
  http_method = aws_api_gateway_method.APImethodForLambdaFunction.http_method
  status_code = aws_api_gateway_method_response.APIgatewayMethodResponse.status_code

  response_templates = {
    "application/json" = ""
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
  depends_on = [
    aws_api_gateway_method_response.APIgatewayMethodResponse
  ]
}
### Specifying method response for integrating API gateway with Lambda function for fetching volume
resource "aws_api_gateway_method_response" "APIgatewayMethodResponse" {
  rest_api_id = aws_api_gateway_rest_api.SearchES-API.id
  resource_id = aws_api_gateway_resource.APIresourceForVolumeFetch.id
  http_method = aws_api_gateway_method.APImethodForLambdaFunction.http_method
  status_code = 200
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}
#Getting permission from Lambda function to API GAteway
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "${local.resource_name_prefix}-${local.lambda_code_files}-AllowExecutionFromAPIGateway-${random_id.unique_SearchUI_id.dec}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function_get_es_volumes.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.SearchES-API.id}/${aws_api_gateway_stage.StageTheAPIdeployed.stage_name}/GET${aws_api_gateway_resource.APIresourceForVolumeFetch.path}"
}

#Enable Cors

resource "aws_api_gateway_method" "CORSmethodForLambdaFunction" {
  rest_api_id   = aws_api_gateway_rest_api.SearchES-API.id
  resource_id   = aws_api_gateway_resource.APIresourceForVolumeFetch.id
  http_method   = "OPTIONS"
  authorization = "NONE"
  depends_on = [
    aws_api_gateway_method.CORSmethodForLambdaFunction,
    aws_api_gateway_resource.APIresourceForVolumeFetch
  ]
}
resource "aws_api_gateway_integration" "EnableCORSwithMock" {
  rest_api_id = aws_api_gateway_rest_api.SearchES-API.id
  resource_id = aws_api_gateway_resource.APIresourceForVolumeFetch.id
  http_method = aws_api_gateway_method.CORSmethodForLambdaFunction.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = jsonencode(
      {
        statusCode = 200
      }
    )
  }
  depends_on = [
    aws_api_gateway_rest_api.SearchES-API,
    aws_api_gateway_resource.APIresourceForVolumeFetch,
    aws_api_gateway_method.APImethodForLambdaFunction,
    aws_api_gateway_method.CORSmethodForLambdaFunction,
    aws_api_gateway_integration.IntegratingLambdaFunctionWithAPIgateway
  ]
}

resource "aws_api_gateway_method_response" "APIgatewayMethodResponseCORS" {
  rest_api_id = aws_api_gateway_rest_api.SearchES-API.id
  resource_id = aws_api_gateway_resource.APIresourceForVolumeFetch.id
  http_method = aws_api_gateway_method.CORSmethodForLambdaFunction.http_method
  status_code = 200
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
  depends_on = [aws_api_gateway_method.CORSmethodForLambdaFunction]
}

resource "aws_api_gateway_integration_response" "rest_api_test_integration_response_CORS" {

  rest_api_id       = aws_api_gateway_rest_api.SearchES-API.id
  resource_id       = aws_api_gateway_resource.APIresourceForVolumeFetch.id
  http_method       = aws_api_gateway_method.CORSmethodForLambdaFunction.http_method
  status_code       = aws_api_gateway_method_response.APIgatewayMethodResponseCORS.status_code
  selection_pattern = ""

  response_templates = {
    "application/json" = ""
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  depends_on = [
    aws_api_gateway_integration.EnableCORSwithMock,
    aws_api_gateway_method_response.APIgatewayMethodResponseCORS
  ]
}


#Deploying the API created
resource "aws_api_gateway_deployment" "APIdeploymentOfLambdaFunction" {
  rest_api_id = aws_api_gateway_rest_api.SearchES-API.id

  triggers = {

    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.APIresourceForVolumeFetch.id,
      aws_api_gateway_method.APImethodForLambdaFunction.id,
      aws_api_gateway_integration.IntegratingLambdaFunctionWithAPIgateway.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
  depends_on = [
    aws_api_gateway_rest_api.SearchES-API,
    aws_api_gateway_integration.IntegratingLambdaFunctionWithAPIgateway,
    aws_api_gateway_integration.EnableCORSwithMock,
    aws_api_gateway_method_response.APIgatewayMethodResponseCORS,
    aws_api_gateway_integration.IntegratingLambdaFunctionWithSearchUI,
    aws_api_gateway_integration.EnableCORSwithMockSearchUI,
    aws_api_gateway_method_response.APIgatewayMethodResponseSearchUICORS

  ]
}

################### END - API Gateway setup for Get Volume Lambda ####################################################

### Staging the Deployed API
resource "aws_api_gateway_stage" "StageTheAPIdeployed" {
  deployment_id = aws_api_gateway_deployment.APIdeploymentOfLambdaFunction.id
  rest_api_id   = aws_api_gateway_rest_api.SearchES-API.id
  stage_name    = local.stage_name
}

################### START - API Gateway setup for Search ES Lambda ####################################################

#Creating resource for Search UI
resource "aws_api_gateway_resource" "APIresourceForSearchUI" {

  path_part   = "search-es"
  parent_id   = aws_api_gateway_rest_api.SearchES-API.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.SearchES-API.id
  depends_on = [
    aws_api_gateway_rest_api.SearchES-API
  ]
}

resource "aws_api_gateway_method" "APImethodForSearchUI" {
  rest_api_id   = aws_api_gateway_rest_api.SearchES-API.id
  resource_id   = aws_api_gateway_resource.APIresourceForSearchUI.id
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.querystring.q" = true
  }
  depends_on = [
    aws_api_gateway_resource.APIresourceForSearchUI
  ]
}

### Integrating the API Gateway with the Lambda function to deploy Search UI
resource "aws_api_gateway_integration" "IntegratingLambdaFunctionWithSearchUI" {
  rest_api_id             = aws_api_gateway_rest_api.SearchES-API.id
  resource_id             = aws_api_gateway_resource.APIresourceForSearchUI.id
  http_method             = aws_api_gateway_method.APImethodForSearchUI.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.lambda_function_search_es.arn}/invocations"
  request_templates = {
    "application/json" = jsonencode(
      {
        statusCode = 200
      }
    )
  }
  depends_on = [
    aws_api_gateway_rest_api.SearchES-API,
    aws_api_gateway_resource.APIresourceForSearchUI,
    aws_api_gateway_method.APImethodForSearchUI
  ]

}

#Specifying integration response of the lambda function with the API gateway for fetching volume
resource "aws_api_gateway_integration_response" "APIintegrationResponseOfLambdafunctionSearchUI" {
  rest_api_id = aws_api_gateway_rest_api.SearchES-API.id
  resource_id = aws_api_gateway_resource.APIresourceForSearchUI.id
  http_method = aws_api_gateway_method.APImethodForSearchUI.http_method
  status_code = aws_api_gateway_method_response.APIgatewaySearchUIMethodResponse.status_code

  response_templates = {
    "application/json" = ""
  }

}

#Specifying method response for integrating API gateway with Search UI
resource "aws_api_gateway_method_response" "APIgatewaySearchUIMethodResponse" {
  rest_api_id = aws_api_gateway_rest_api.SearchES-API.id
  resource_id = aws_api_gateway_resource.APIresourceForSearchUI.id
  http_method = aws_api_gateway_method.APImethodForSearchUI.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}



#Getting permission from Lambda function to API GAteway
resource "aws_lambda_permission" "apigw_lambdaSearchUI" {
  statement_id  = "${local.resource_name_prefix}-${local.lambda_code_files}-AllowExecutionFromAPIGatewayForSearchUI-${random_id.unique_SearchUI_id.dec}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function_search_es.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.SearchES-API.id}/${aws_api_gateway_stage.StageTheAPIdeployed.stage_name}/GET${aws_api_gateway_resource.APIresourceForSearchUI.path}"
}


#Enable Cors for 

resource "aws_api_gateway_method" "CORSmethodForLambdaFunctionUI" {
  rest_api_id   = aws_api_gateway_rest_api.SearchES-API.id
  resource_id   = aws_api_gateway_resource.APIresourceForSearchUI.id
  http_method   = "OPTIONS"
  authorization = "NONE"
  depends_on = [
    aws_api_gateway_resource.APIresourceForSearchUI
  ]
}
resource "aws_api_gateway_integration" "EnableCORSwithMockSearchUI" {
  rest_api_id = aws_api_gateway_rest_api.SearchES-API.id
  resource_id = aws_api_gateway_resource.APIresourceForSearchUI.id
  http_method = aws_api_gateway_method.CORSmethodForLambdaFunctionUI.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = jsonencode(
      {
        statusCode = 200
      }
    )
  }
  depends_on = [
    aws_api_gateway_rest_api.SearchES-API,
    aws_api_gateway_resource.APIresourceForSearchUI,
    aws_api_gateway_method.CORSmethodForLambdaFunctionUI,
    aws_api_gateway_method.CORSmethodForLambdaFunctionUI,
    aws_api_gateway_integration.IntegratingLambdaFunctionWithSearchUI
  ]
}


resource "aws_api_gateway_method_response" "APIgatewayMethodResponseSearchUICORS" {
  rest_api_id = aws_api_gateway_rest_api.SearchES-API.id
  resource_id = aws_api_gateway_resource.APIresourceForSearchUI.id
  http_method = aws_api_gateway_method.CORSmethodForLambdaFunctionUI.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

}

resource "aws_api_gateway_integration_response" "rest_api_test_integration_response_SearchUI_CORS" {

  rest_api_id       = aws_api_gateway_rest_api.SearchES-API.id
  resource_id       = aws_api_gateway_resource.APIresourceForSearchUI.id
  http_method       = aws_api_gateway_method.CORSmethodForLambdaFunctionUI.http_method
  status_code       = aws_api_gateway_method_response.APIgatewayMethodResponseSearchUICORS.status_code
  selection_pattern = ""

  response_templates = {
    "application/json" = ""
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  depends_on = [
    aws_api_gateway_integration.EnableCORSwithMockSearchUI,
    aws_api_gateway_method_response.APIgatewayMethodResponseSearchUICORS
  ]
}


################### END - API Gateway setup for Search ES Lambda ####################################################

output "search_api_endpoint" {
  value = "${aws_api_gateway_deployment.APIdeploymentOfLambdaFunction.invoke_url}${aws_api_gateway_stage.StageTheAPIdeployed.stage_name}${aws_api_gateway_resource.APIresourceForSearchUI.path}"
}

output "volume_api_endpoint" {
  value = "${aws_api_gateway_deployment.APIdeploymentOfLambdaFunction.invoke_url}${aws_api_gateway_stage.StageTheAPIdeployed.stage_name}${aws_api_gateway_resource.APIresourceForVolumeFetch.path}"
}

################### START - Create API Gateway Response Object ####################################################

locals {
  response_map = {
    ACCESS_DENIED                  = 403
    API_CONFIGURATION_ERROR        = 500
    AUTHORIZER_CONFIGURATION_ERROR = 500
    AUTHORIZER_FAILURE             = 500
    BAD_REQUEST_PARAMETERS         = 400
    BAD_REQUEST_BODY               = 400
    DEFAULT_4XX                    = null
    DEFAULT_5XX                    = null
    EXPIRED_TOKEN                  = 403
    INTEGRATION_FAILURE            = 504
    INTEGRATION_TIMEOUT            = 504
    INVALID_API_KEY                = 403
    INVALID_SIGNATURE              = 403
    MISSING_AUTHENTICATION_TOKEN   = 403
    QUOTA_EXCEEDED                 = 429
    REQUEST_TOO_LARGE              = 413
    RESOURCE_NOT_FOUND             = 404
    THROTTLED                      = 429
    UNAUTHORIZED                   = 401
    UNSUPPORTED_MEDIA_TYPE         = 415
    WAF_FILTERED                   = 403
  }
}
resource "aws_api_gateway_gateway_response" "response" {
  for_each = local.response_map

  rest_api_id   = aws_api_gateway_rest_api.SearchES-API.id
  response_type = each.key
  status_code   = each.value

  response_templates = {
    "application/json" = "{\"message\": $context.error.messageString}"
  }
  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin" = "'*'"
  }
}
################### END - Create API Gateway Response Object ####################################################
# Our api which we put inside the js code:
# https://nzv7g5fdy3.execute-api.us-east-2.amazonaws.com/dev/es-volume
# rest_api_id = aws_api_gateway_rest_api.SearchES-API.id
# vpc_endpoint_id = local.vpc_endpoint_id
# Example of Correct api Format  :
# https://nzv7g5fdy3-vpce-01761e00bb5fbc4c9.execute-api.us-east-2.amazonaws.com/dev/es-volume
locals {
  volume_api_url="https://${aws_api_gateway_rest_api.SearchES-API.id}-${local.vpc_endpoint_id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_stage.StageTheAPIdeployed.stage_name}${aws_api_gateway_resource.APIresourceForVolumeFetch.path}"
  search_api_url="https://${aws_api_gateway_rest_api.SearchES-API.id}-${local.vpc_endpoint_id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_stage.StageTheAPIdeployed.stage_name}${aws_api_gateway_resource.APIresourceForSearchUI.path}"
}
resource "null_resource" "update_search_js" {
  provisioner "local-exec" {
    # command = "sed -i 's#var volume_api.*$#var volume_api = \"${aws_api_gateway_deployment.APIdeploymentOfLambdaFunction.invoke_url}${aws_api_gateway_stage.StageTheAPIdeployed.stage_name}${aws_api_gateway_resource.APIresourceForVolumeFetch.path}\"; #g' SearchUI_Web/search.js"
    command = "sed -i 's#var volume_api.*$#var volume_api = \"${local.volume_api_url}\"; #g' SearchUI_Web/search.js"
  }
  provisioner "local-exec" {
    command = "sed -i 's#var search_api.*$#var search_api = \"${local.search_api_url}\"; #g' SearchUI_Web/search.js"
  }
  provisioner "local-exec" {
    command = "sudo service apache2 restart"
  }
  depends_on = [aws_api_gateway_rest_api.SearchES-API]
}
