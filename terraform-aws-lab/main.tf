################################################################################
# 1. Provider 설정
# - 클라우드 제공자(AWS)와 리전을 정의합니다.
################################################################################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # 최신 5.x 버전 사용
    }
  }
}

provider "aws" {
  region = "ap-northeast-2" # 서울 리전
  # profile = "default"     # ~/.aws/credentials에 여러 프로필이 있다면 지정 가능
}

################################################################################
# 2. VPC (Virtual Private Cloud)
# - 네트워크 격리의 기본이 되는 VPC와 서브넷을 생성합니다.
################################################################################
resource "aws_vpc" "main_vpc" {
  cidr_block       = "10.0.0.0/16"  # VPC의 IP 대역 (최대 65,536개 IP)
  instance_tenancy = "default"      # "default" 또는 "dedicated" (전용 하드웨어)

  # DNS 설정: VPC 내 인스턴스가 DNS 호스트네임을 가질지 여부
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "terra-lab-vpc"
  }
}

# [Subnet] 퍼블릭 서브넷 (외부 통신 가능)
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = false
# map_public_ip_on_launch = true # 인스턴스 생성 시 자동으로 퍼블릭 IP 할당 비용 존재함 주의

  tags = {
    Name = "terra-lab-public-subnet"
  }
}

# [Subnet] 프라이빗 서브넷 (RDS 등 내부용)
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "terra-lab-private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-northeast-2c" # RDS는 다중 AZ 구성을 위해 다른 AZ 필요

  tags = {
    Name = "terra-lab-private-subnet-2"
  }
}

# [Internet Gateway] 외부 인터넷 연결을 위한 게이트웨이
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "terra-lab-igw"
  }
}

# [Route Table] 퍼블릭 서브넷용 라우팅 테이블
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"             # 모든 트래픽을
    gateway_id = aws_internet_gateway.igw.id # IGW로 보냄
  }

  tags = {
    Name = "terra-lab-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

################################################################################
# 3. Security Group (보안 그룹)
# - 방화벽 역할을 합니다.
################################################################################
resource "aws_security_group" "web_sg" {
  name        = "terra-lab-web-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.main_vpc.id

  # 인바운드 규칙 (들어오는 트래픽)
  ingress {
    description = "SSH from Anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 보안상 내 IP로 제한하는 것이 좋습니다.
  }

  ingress {
    description = "HTTP from Anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 아웃바운드 규칙 (나가는 트래픽 - 보통 전체 허용)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # 모든 프로토콜
    cidr_blocks = ["0.0.0.0/0"]
  }
}

################################################################################
# 4. EC2 (Elastic Compute Cloud)
# - 가상 서버 인스턴스입니다.
################################################################################
# 최신 Amazon Linux 2 AMI ID를 동적으로 조회
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "web_server" {
  ami           = data.aws_ami.amazon_linux.id # 위에서 조회한 이미지 ID
  instance_type = "t2.micro"                   # 인스턴스 사양 (CPU, RAM)

  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # 퍼블릭 IP 할당 방지 (비용 0원을 위한 핵심 설정)
  associate_public_ip_address = false

  # 스토리지 설정 (Root Volume)
  root_block_device {
    volume_size = 8     # GB 단위
    volume_type = "gp3" # SSD 타입 (gp2, gp3, io1 등)
    encrypted   = true  # 디스크 암호화 여부
    
    # 종료 시 볼륨 삭제 여부 (데이터 보존 필요 시 false)
    delete_on_termination = true 
  }

  # 사용자 데이터 (부팅 시 실행될 스크립트)
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Hello Terraform" > /var/www/html/index.html
              EOF

  tags = {
    Name = "terra-lab-ec2"
  }
}

################################################################################
# 5. S3 (Simple Storage Service)
# - 객체 스토리지입니다.
################################################################################
resource "aws_s3_bucket" "my_bucket" {
  bucket = "terra-lab-unique-bucket-name-13467958264" # 전 세계적으로 고유해야 함
  
  # 실수로 삭제되는 것을 방지 (테스트 시엔 불편할 수 있어 false 처리)
  force_destroy = true 

  tags = {
    Name = "terra-lab-bucket"
  }
}

# 버킷 버전 관리 설정 (파일 덮어쓰기/삭제 시 복구 가능)
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.my_bucket.id
  versioning_configuration {
    status = "Enabled" # "Enabled" or "Suspended"
  }
}

################################################################################
# 6. RDS (Relational Database Service)
# - 관리형 데이터베이스입니다.
################################################################################
# DB 서브넷 그룹 (RDS가 위치할 서브넷 지정)
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "terra-lab-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage    = 10              # 스토리지 용량 (GB)
  db_name              = "mydb"          # 초기 데이터베이스 이름
  engine               = "mysql"         # 엔진 종류 (mysql, postgres, oracle 등)
  engine_version       = "8.0"           # 엔진 버전
  instance_class       = "db.t3.micro"   # 인스턴스 사양
  username             = "admin"         # 마스터 사용자명
  password             = "password1234!" # 마스터 비밀번호 (실무에선 Secret Manager 사용 권장)
  parameter_group_name = "default.mysql8.0"
  
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  
  # 스냅샷 없이 바로 삭제 가능하도록 설정 (테스트용)
  skip_final_snapshot  = true
  
  # 퍼블릭 액세스 차단 (보안)
  publicly_accessible  = false
  
  # 스토리지 자동 확장 설정
  max_allocated_storage = 20 

  tags = {
    Name = "terra-lab-rds"
  }
}

################################################################################
# 7. Lambda (Serverless Compute)
# - 서버리스 함수 실행 환경입니다.
################################################################################
# Lambda가 사용할 IAM 역할 (권한)
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Lambda 함수 정의
resource "aws_lambda_function" "test_lambda" {
  # 로컬에 있는 zip 파일 경로 (사전에 생성 필요)
  filename      = "lambda_function.zip" 
  function_name = "terra_lab_function"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "main.handler" # 실행 진입점 (파일명.함수명)

  # 소스 코드 해시값 (변경 감지용)
  source_code_hash = filebase64sha256("lambda_function.zip")

  runtime = "python3.9" # 실행 런타임 (nodejs, python, java 등)

  # 환경 변수 설정
  environment {
    variables = {
      foo = "bar"
    }
  }
  
  timeout     = 10  # 최대 실행 시간 (초)
  memory_size = 128 # 할당 메모리 (MB)
}

################################################################################
# 8. SNS (Simple Notification Service)
# - 메시지 게시 및 구독 서비스입니다.
################################################################################
resource "aws_sns_topic" "user_updates" {
  name = "terra-lab-user-updates"
  display_name = "User Update Notification" # SMS 전송 시 표시될 이름
}

resource "aws_sns_topic_subscription" "email_target" {
  topic_arn = aws_sns_topic.user_updates.arn
  protocol  = "email"
  endpoint  = "example@example.com" # 실제 수신 가능한 이메일 주소 입력
}

################################################################################
# 9. CloudWatch (Monitoring)
# - 리소스 모니터링 및 알람입니다.
################################################################################
# EC2 CPU 사용률 경보 생성
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_alarm" {
  alarm_name          = "terra-lab-ec2-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2" # 평가 횟수 (2번 연속 초과 시)
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120" # 초 단위 (2분)
  statistic           = "Average"
  threshold           = "80" # 80% 초과 시 경보
  
  alarm_description   = "This metric monitors ec2 cpu utilization"
  
  # 알람 발생 시 실행할 작업 (SNS 주제 연결)
  alarm_actions       = [aws_sns_topic.user_updates.arn]

  # 모니터링 대상 인스턴스 ID
  dimensions = {
    InstanceId = aws_instance.web_server.id
  }
}