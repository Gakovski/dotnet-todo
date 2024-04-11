terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}


resource "aws_vpc" "CUSTOM_VPC" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "Todo API - VPC"
  }
}

resource "aws_internet_gateway" "CUSTOM_IGW" {
  vpc_id = aws_vpc.CUSTOM_VPC.id

  tags = {
    Name = "Todo API - Internet Gateway"
  }
}


resource "aws_route_table" "CUSTOM_RT" {
  vpc_id = aws_vpc.CUSTOM_VPC.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.CUSTOM_IGW.id
    }

  route {
      ipv6_cidr_block        = "::/0"
      gateway_id = aws_internet_gateway.CUSTOM_IGW.id 
    }

  tags = {
    Name = "Todo API - Route Table"
  }
}

resource "aws_subnet" "CUSTOM_SUBNET" {
  vpc_id     = aws_vpc.CUSTOM_VPC.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Todo API - Subnet"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.CUSTOM_SUBNET.id
  route_table_id = aws_route_table.CUSTOM_RT.id
}

resource "aws_security_group" "CUSTOM_SG" {
  name        = "Allow Web Trafic"
  description = "Allow Web inbound traffic on port 80, 443"
  vpc_id      = aws_vpc.CUSTOM_VPC.id

  ingress {
      description      = "HTTPS"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }
  ingress  {
      description      = "HTTP"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }
  egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
    }

  tags = {
    Name = "Allow Web traffic"
  }
}

resource "aws_network_interface" "CUSTOM_NIC" {
  subnet_id       = aws_subnet.CUSTOM_SUBNET.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.CUSTOM_SG.id]
}

resource "aws_eip" "CUSTOM_EIP" {
  domain = "vpc"
  network_interface = aws_network_interface.CUSTOM_NIC.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.CUSTOM_IGW]
}

data "aws_ecr_repository" "todo_ecr_private_repo" {
  name = "todo-ecr-private"
}

resource "aws_iam_role" "lambda_role" {
  name = "Todo_API_Lambda_Function_Role"

  assume_role_policy = jsonencode({
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
  })
}

resource "aws_iam_policy" "iam_policy_for_lambda" {
  name        = "aws_iam_policy_for_terraform_aws_lambda_role"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeNetworkInterfaces"
        ],
        "Resource": "*",
        "Effect": "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
}

resource "aws_lambda_function" "todo_lambda_function" {
  function_name = "todo-lambda"
  timeout       = 5 # seconds
  image_uri     = "<image_uri>"
  package_type  = "Image"
  depends_on    = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]

  role = aws_iam_role.lambda_role.arn

  vpc_config {
    subnet_ids         = [aws_subnet.CUSTOM_SUBNET.id]
    security_group_ids = [aws_security_group.CUSTOM_SG.id]
  }
}