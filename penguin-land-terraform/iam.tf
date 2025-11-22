# IAM Role for EC2 Instance
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-${var.session_id}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.session_id}-ec2-role"
  }
}

# IAM Policy for EC2 (최소 권한 원칙)
resource "aws_iam_role_policy" "ec2_policy" {
  name = "${var.project_name}-${var.session_id}-ec2-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "dynamodb:*",
          "cloudwatch:*",
          "sns:*",
          "lambda:*",
          "s3:*",
          "vpc:*",
          "logs:*",
          "ssm:*",
          "ssmmessages:*",
          "ec2messages:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach AWS managed policies for SSM and CloudWatch
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# IAM Instance Profile for EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-${var.session_id}-ec2-profile"
  role = aws_iam_role.ec2_role.name

  tags = {
    Name = "${var.project_name}-${var.session_id}-ec2-profile"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-${var.session_id}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.session_id}-lambda-role"
  }
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-${var.session_id}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricData"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach AWS Lambda Basic Execution Role
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach AWS Lambda VPC Access Execution Role
resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
