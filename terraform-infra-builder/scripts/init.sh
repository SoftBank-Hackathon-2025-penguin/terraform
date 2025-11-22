#!/bin/bash
# scripts/init.sh

set -e
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "========================================"
echo "Terraform 초기화 및 환경 점검"
echo "========================================"

# 1. 필수 도구 점검 (Terraform, AWS CLI)
if ! command -v terraform &> /dev/null; then
    echo "❌ 오류: Terraform이 설치되어 있지 않습니다."
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo "❌ 오류: AWS CLI가 설치되어 있지 않습니다."
    exit 1
fi

# 2. terraform.tfvars 템플릿 생성 (plan.txt의 Object 구조에 맞게 수정됨)
if [ ! -f "$PROJECT_ROOT/terraform.tfvars" ]; then
    echo "⚠️  terraform.tfvars 파일이 없어 기본 템플릿을 생성합니다..."
    
    cat > "$PROJECT_ROOT/terraform.tfvars" << 'EOF'
# 프로젝트 기본 설정
project_name = "my-infra-project"
environment  = "dev"
aws_region   = "ap-northeast-2"

# 모듈 활성화 플래그
enable_vpc        = true
enable_ec2        = true
enable_rds        = false
enable_s3         = false
enable_lambda     = false
enable_cloudwatch = true
enable_sns        = false

# VPC 설정 (Object 타입)
vpc_config = {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  availability_zones   = ["ap-northeast-2a", "ap-northeast-2c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]
}

# EC2 설정
ec2_config = {
  instance_type = "t3.micro"
  ami_id        = ""  # 비워두면 최신 AL2023 사용
  key_name      = ""  # SSM 접속 권장 (키 페어 없어도 됨)
  volume_size   = 20
}

# RDS 설정
rds_config = {
  engine              = "mysql"
  engine_version      = "8.0"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  db_name             = "mydb"
  username            = "admin"
  password            = "changeme123!" # 실제 사용시 변경 필수
  multi_az            = false
  skip_final_snapshot = true
}

# 기타 설정은 필요에 따라 추가...
EOF
    echo "✅ terraform.tfvars 템플릿 생성 완료."
else
    echo "✅ terraform.tfvars 파일이 이미 존재합니다."
fi

# 3. Terraform 초기화
echo "🚀 Terraform init 실행 중..."
cd "$PROJECT_ROOT"
terraform init

echo "========================================"
echo "✅ 초기화 완료. 'terraform plan'을 실행해보세요."
echo "========================================"