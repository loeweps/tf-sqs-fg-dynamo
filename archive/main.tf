terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_iam_role" "fg_task_execution_role" {
  name               = "fg-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}


#Create role for ECS to assume
data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "ecs_task_execution_role" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Attach the above policy to the execution role.
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.fg_task_execution_role
  policy_arn = data.aws_iam_policy.ecs_task_execution_role.arn
}


resource "aws_ecs_task_definition" "testTaskDefinition" {
  family = "service"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  container_definitions = jsonencode([
    {
      name              = ""
      image             = "service-first"
      cpu               = 256
      memory            = 512
      essential         = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])

  network_mode = "awsvpc"
}



#Create a dynamoDb table to hold items
resource "aws_dynamodb_table" "crud_table" {
  name           = "crud-http-items"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

#Create role for Lambda to assume
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Create a role for Lambda function for dynamodb access
resource "aws_iam_role" "dynamo_crud_role" {
  name               = "dynamo-crud-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

#Lambda dynamodb functions
data "archive_file" "dynamo_mjs" {  
  type = "zip"  
  source_file = "./code/index.mjs" 
  output_path = "lambda_function.zip"
}

resource "aws_lambda_function" "crud_function" {
  function_name = "dynamo-crud-function"
  role          = aws_iam_role.dynamo_crud_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  filename      = "lambda_function.zip"
}

resource "aws_iam_policy" "dynamodb_access_policy" {
  name        = "DynamoDbAccessPolicy"
  description = "Policy granting permissions to interact with MongoDB"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Action    = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ],
        Resource  = "arn:aws:dynamodb:*:*:table/crud-http-items"
      },
      {
        Effect    = "Allow",
        Action    = "execute-api:Invoke",
        Resource  = "arn:aws:execute-api:*:*:*"
      }
    ]
  })
}
