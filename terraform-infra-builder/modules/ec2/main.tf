# modules/ec2/main.tf

# [개선 2] AMI 데이터 소스 추가 - ami_id가 비어있을 때 최신 Amazon Linux 2023 자동 선택
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# 보안 그룹
resource "aws_security_group" "ec2" {
  count = var.vpc_id != null ? 1 : 0
  
  name        = "${var.project_name}-${var.environment}-ec2-sg"
  description = "Security group for EC2 with refined rules"
  vpc_id      = var.vpc_id

  # HTTP (80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP"
  }

  # HTTPS (443)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS"
  }

  # SSH (22) - 특정 IP에서만 열거나 SSM 사용 시 제거 가능
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 운영 시 관리자 IP로 제한 권장
    description = "Allow SSH"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-sg"
  }
}

# EC2 인스턴스
resource "aws_instance" "main" {
  # [개선 2] ami_id가 비어있으면 최신 AL2023 자동 선택
  ami           = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  # IAM 프로파일 연결 (iam.tf에서 생성)
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.vpc_id != null ? [aws_security_group.ec2[0].id] : var.vpc_security_group_ids

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.volume_size
    delete_on_termination = true
    encrypted             = true
  }

  user_data = fileexists("${path.module}/userdata.sh") ? file("${path.module}/userdata.sh") : null

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2"
  }
}

# Elastic IP (옵션)
resource "aws_eip" "main" {
  count = var.allocate_eip ? 1 : 0

  instance = aws_instance.main.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-eip"
  }
}