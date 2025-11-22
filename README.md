완전한 README 문서를 작성해드리겠습니다.[1][2][3]

# README.md

```markdown
# Terraform AWS Infrastructure Builder

프론트엔드에서 선택한 AWS 리소스를 자동으로 생성하고 연결하는 모듈형 Terraform 프로젝트입니다[web:1][web:89].

## 📋 목차

- [개요](#개요)
- [지원하는 AWS 서비스](#지원하는-aws-서비스)
- [사전 요구사항](#사전-요구사항)
- [프로젝트 구조](#프로젝트-구조)
- [빠른 시작](#빠른-시작)
- [개별 서비스 생성 방법](#개별-서비스-생성-방법)
- [파라미터 상세 설명](#파라미터-상세-설명)
- [연결된 인프라 생성 예시](#연결된-인프라-생성-예시)
- [고급 사용법](#고급-사용법)
- [트러블슈팅](#트러블슈팅)
- [라이센스](#라이센스)

---

## 개요

이 프로젝트는 **모듈형 Terraform 구성**으로 설계되어 각 AWS 서비스를 독립적으로 또는 조합하여 생성할 수 있습니다[web:92].

### 주요 특징

- ✅ **선택적 리소스 생성**: 필요한 서비스만 선택하여 생성
- ✅ **자동 연결 설정**: EC2-S3, EC2-RDS, EC2-CloudWatch 자동 연결
- ✅ **다중 인스턴스 지원**: 각 서비스의 여러 인스턴스 동시 생성
- ✅ **보안 중심 설계**: 암호화, 최소 권한 원칙 적용
- ✅ **프로덕션 대응**: 백업, 모니터링, 알람 자동 설정

---

## 지원하는 AWS 서비스

| 서비스 | 독립 생성 | 다중 인스턴스 | 자동 연결 대상 |
|--------|----------|--------------|---------------|
| **VPC** | ✅ | ❌ (1개) | EC2, RDS, Lambda |
| **EC2** | ⚠️ (VPC 필요) | ✅ | S3, RDS, CloudWatch |
| **RDS** | ⚠️ (VPC 필요) | ✅ | EC2, S3 |
| **S3** | ✅ | ✅ | EC2, RDS, Lambda |
| **CloudWatch** | ✅ | ❌ (1개) | EC2, RDS, SNS |
| **SNS** | ✅ | ❌ (1개) | CloudWatch, Lambda |
| **Lambda** | ✅ | ✅ | S3, SNS, VPC |

---

## 사전 요구사항

### 필수 도구

```
# Terraform 설치 확인
terraform version
# Terraform v1.5.0 이상 필요

# AWS CLI 설치 및 구성
aws --version
aws configure
```

### AWS 자격증명 설정

```
# AWS Credentials 설정
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="ap-northeast-2"

# 또는 AWS CLI로 설정
aws configure
```

### SSH 키 페어 생성 (EC2 사용 시)

```
aws ec2 create-key-pair \
  --key-name my-terraform-key \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/my-terraform-key.pem

chmod 400 ~/.ssh/my-terraform-key.pem
```

---

## 프로젝트 구조

```
terraform-infra-builder/
├── main.tf                      # 루트 모듈 (서비스 통합)
├── variables.tf                 # 전역 변수 정의
├── outputs.tf                   # 출력 값
├── versions.tf                  # Provider 버전
├── terraform.tfvars.example     # 설정 예시 파일
│
├── modules/
│   ├── vpc/                     # VPC 모듈
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── ec2/                     # EC2 모듈
│   │   ├── main.tf
│   │   ├── user_data.sh         # 초기화 스크립트
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── rds/                     # RDS 모듈
│   ├── s3/                      # S3 모듈
│   ├── cloudwatch/              # CloudWatch 모듈
│   ├── sns/                     # SNS 모듈
│   └── lambda/                  # Lambda 모듈
│
└── examples/                    # 사용 예시
    ├── 01-s3-only/
    ├── 02-vpc-ec2/
    ├── 03-full-stack/
    └── 04-serverless/
```

---

## 빠른 시작

### 1. 전체 인프라 한번에 생성

```
# 1. terraform.tfvars 파일 생성
cp terraform.tfvars.example terraform.tfvars

# 2. 파일 수정 (원하는 서비스 활성화)
vim terraform.tfvars

# 3. Terraform 초기화
terraform init

# 4. 실행 계획 확인
terraform plan

# 5. 인프라 생성
terraform apply

# 6. 생성된 리소스 확인
terraform output
```

### 2. 최소 설정 예시 (S3만 생성)

`terraform.tfvars` 파일:

```
project_name = "my-project"
environment  = "dev"
aws_region   = "ap-northeast-2"

# S3만 활성화
enable_s3 = true

s3_buckets = {
  "data-storage" = {
    versioning_enabled = true
    enable_encryption  = true
    lifecycle_rules    = []
  }
}
```

```
terraform init
terraform apply -auto-approve
```

---

## 개별 서비스 생성 방법

### 1️⃣ S3 버킷만 생성

**사용 시나리오**: 스토리지만 필요한 경우 (독립 실행 가능)[web:93][web:94]

**terraform.tfvars**:
```
project_name = "storage-project"
environment  = "prod"
aws_region   = "ap-northeast-2"

# S3만 활성화
enable_s3 = true

# 여러 버킷 동시 생성 가능
s3_buckets = {
  "user-uploads" = {
    versioning_enabled = true
    enable_encryption  = true
    lifecycle_rules = [
      {
        id                       = "delete-old-files"
        enabled                  = true
        expiration_days          = 90
        transition_days          = 30
        transition_storage_class = "STANDARD_IA"
      }
    ]
  },
  "app-logs" = {
    versioning_enabled = false
    enable_encryption  = true
    lifecycle_rules = [
      {
        id                       = "archive-logs"
        enabled                  = true
        expiration_days          = 365
        transition_days          = 90
        transition_storage_class = "GLACIER"
      }
    ]
  },
  "backup-data" = {
    versioning_enabled = true
    enable_encryption  = true
    lifecycle_rules    = []
  }
}
```

**실행**:
```
terraform init
terraform plan
terraform apply

# 특정 버킷만 생성하려면
terraform apply -target='module.s3["user-uploads"]'

# 출력 확인
terraform output
```

**예상 출력**:
```
s3_bucket_name_user-uploads = "storage-project-prod-user-uploads"
s3_bucket_arn_user-uploads  = "arn:aws:s3:::storage-project-prod-user-uploads"
```

---

### 2️⃣ CloudWatch + SNS만 생성 (모니터링 전용)

**사용 시나리오**: 기존 인프라에 모니터링 추가[web:89]

**terraform.tfvars**:
```
project_name = "monitoring"
environment  = "prod"
aws_region   = "ap-northeast-2"

enable_cloudwatch = true
enable_sns        = true

# CloudWatch 설정
log_retention_days = 30

# SNS 설정
sns_topic_name = "infrastructure-alerts"
sns_email_endpoints = [
  "devops@company.com",
  "oncall@company.com"
]
```

**실행**:
```
terraform init
terraform apply

# CloudWatch 로그 그룹 확인
aws logs describe-log-groups --log-group-name-prefix "/aws/monitoring"

# SNS 토픽 확인
aws sns list-topics
```

---

### 3️⃣ Lambda 함수만 생성 (서버리스)

**사용 시나리오**: 서버리스 애플리케이션[web:92]

**terraform.tfvars**:
```
project_name = "serverless-api"
environment  = "dev"
aws_region   = "ap-northeast-2"

enable_lambda = true

lambda_functions = {
  "image-processor" = {
    runtime          = "python3.11"
    handler          = "lambda_function.handler"
    source_code_path = "./lambda/image-processor"
    memory_size      = 1024
    timeout          = 300
    environment_vars = {
      BUCKET_NAME = "my-bucket"
      MAX_SIZE    = "5242880"
    }
    enable_s3_access  = false
    enable_vpc_access = false
  },
  "data-validator" = {
    runtime          = "python3.11"
    handler          = "index.handler"
    source_code_path = "./lambda/validator"
    memory_size      = 512
    timeout          = 60
    environment_vars = {
      API_ENDPOINT = "https://api.example.com"
    }
    enable_s3_access  = false
    enable_vpc_access = false
  }
}
```

**Lambda 코드 준비**:
```
# Lambda 소스 코드 디렉토리 생성
mkdir -p lambda/image-processor
cat > lambda/image-processor/lambda_function.py <<EOF
def handler(event, context):
    print("Image processing started")
    return {"statusCode": 200, "body": "Success"}
EOF

# 패키징 (Terraform이 자동으로 처리하지만 미리 확인 가능)
cd lambda/image-processor
zip -r ../image-processor.zip .
cd ../..
```

**실행**:
```
terraform init
terraform apply

# 특정 Lambda만 생성
terraform apply -target='module.lambda["image-processor"]'

# Lambda 함수 테스트
aws lambda invoke \
  --function-name serverless-api-dev-image-processor \
  --payload '{"test": "data"}' \
  response.json
```

---

### 4️⃣ RDS만 생성 (기존 VPC 사용)

**사용 시나리오**: 기존 VPC에 데이터베이스 추가[web:13]

**사전 요구사항**: 기존 VPC와 Private Subnet ID 필요

```
# 기존 VPC 정보 조회
aws ec2 describe-vpcs
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-xxxxx"
```

**terraform.tfvars**:
```
project_name = "database-cluster"
environment  = "prod"
aws_region   = "ap-northeast-2"

# VPC 생성 비활성화, 기존 VPC 사용
enable_vpc = false
existing_vpc_id = "vpc-0a1b2c3d4e5f6g7h8"
existing_private_subnet_ids = [
  "subnet-0123456789abcdef0",
  "subnet-abcdef0123456789a"
]

# RDS 활성화
enable_rds = true

rds_instances = {
  "master-db" = {
    engine            = "mysql"
    engine_version    = "8.0.35"
    instance_class    = "db.r5.large"
    allocated_storage = 100
    db_name           = "production"
    username          = "admin"
    password          = "SuperSecurePassword123!"  # 실제로는 AWS Secrets Manager 권장
    enable_s3_backup  = false
  },
  "analytics-db" = {
    engine            = "postgres"
    engine_version    = "15.3"
    instance_class    = "db.t3.medium"
    allocated_storage = 50
    db_name           = "analytics"
    username          = "admin"
    password          = "AnotherSecurePass456!"
    enable_s3_backup  = false
  }
}
```

**실행**:
```
terraform init
terraform apply

# 특정 RDS만 생성
terraform apply -target='module.rds["master-db"]'

# RDS 엔드포인트 확인
terraform output | grep rds_endpoint
```

**연결 테스트**:
```
# MySQL 연결
mysql -h <rds_endpoint> -u admin -p production

# PostgreSQL 연결
psql -h <rds_endpoint> -U admin -d analytics
```

---

### 5️⃣ VPC만 생성 (네트워크 기반)

**사용 시나리오**: 네트워크 인프라 먼저 구축[web:89]

**terraform.tfvars**:
```
project_name = "network-foundation"
environment  = "prod"
aws_region   = "ap-northeast-2"

enable_vpc = true

# VPC 설정
vpc_cidr = "10.0.0.0/16"
availability_zones = [
  "ap-northeast-2a",
  "ap-northeast-2b",
  "ap-northeast-2c"
]
public_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24",
  "10.0.3.0/24"
]
private_subnet_cidrs = [
  "10.0.11.0/24",
  "10.0.12.0/24",
  "10.0.13.0/24"
]
enable_nat_gateway = true
```

**실행**:
```
terraform init
terraform apply

# VPC 정보 저장 (다음 단계에서 사용)
terraform output vpc_id > vpc_info.txt
terraform output private_subnet_ids >> vpc_info.txt
terraform output public_subnet_ids >> vpc_info.txt
```

---

## 파라미터 상세 설명

### 전역 파라미터

| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|---------|------|------|--------|------|
| `project_name` | string | ✅ | - | 프로젝트 이름 (모든 리소스 이름에 포함) |
| `environment` | string | ✅ | - | 환경 (dev, staging, prod) |
| `aws_region` | string | ❌ | `ap-northeast-2` | AWS 리전 |
| `key_name` | string | ❌ | `""` | EC2 SSH 키 페어 이름 |

### 서비스 활성화 플래그

| 파라미터 | 타입 | 기본값 | 설명 |
|---------|------|--------|------|
| `enable_vpc` | bool | `false` | VPC 생성 여부 |
| `enable_ec2` | bool | `false` | EC2 생성 여부 |
| `enable_rds` | bool | `false` | RDS 생성 여부 |
| `enable_s3` | bool | `false` | S3 생성 여부 |
| `enable_cloudwatch` | bool | `false` | CloudWatch 생성 여부 |
| `enable_sns` | bool | `false` | SNS 생성 여부 |
| `enable_lambda` | bool | `false` | Lambda 생성 여부 |

### VPC 파라미터

```
variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "사용할 가용 영역 목록"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_subnet_cidrs" {
  description = "퍼블릭 서브넷 CIDR 목록"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "프라이빗 서브넷 CIDR 목록"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "enable_nat_gateway" {
  description = "NAT Gateway 생성 여부 (프라이빗 서브넷 인터넷 접근)"
  type        = bool
  default     = true
}
```

### EC2 파라미터

```
variable "ec2_instances" {
  description = "생성할 EC2 인스턴스 맵"
  type = map(object({
    instance_type          = string  # t3.micro, t3.small, t3.medium 등
    ami_id                 = string  # Amazon Linux 2023: ami-0c9c942bd7bf113a2
    enable_s3_access       = bool    # S3 버킷 접근 권한 부여
    enable_rds_access      = bool    # RDS 접근 보안 그룹 설정
    enable_cloudwatch_logs = bool    # CloudWatch Logs 자동 수집
  }))
  default = {}
}
```

**AMI ID 조회**:
```
# Amazon Linux 2023 최신 AMI
aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-*-x86_64" \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
  --output text

# Ubuntu 22.04 LTS 최신 AMI
aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
  --output text
```

### RDS 파라미터

```
variable "rds_instances" {
  type = map(object({
    engine            = string  # mysql, postgres, mariadb, aurora-mysql 등
    engine_version    = string  # MySQL: 8.0.35, PostgreSQL: 15.3
    instance_class    = string  # db.t3.micro, db.t3.small, db.r5.large 등
    allocated_storage = number  # GB 단위 (최소 20)
    db_name           = string  # 데이터베이스 이름
    username          = string  # 마스터 사용자 이름
    password          = string  # 마스터 비밀번호 (최소 8자)
    enable_s3_backup  = bool    # S3 백업 활성화 여부
  }))
  default   = {}
  sensitive = true  # 비밀번호 보호
}
```

**엔진 버전 조회**:
```
# MySQL 사용 가능 버전
aws rds describe-db-engine-versions \
  --engine mysql \
  --query 'DBEngineVersions[*].EngineVersion' \
  --output table

# PostgreSQL 사용 가능 버전
aws rds describe-db-engine-versions \
  --engine postgres \
  --query 'DBEngineVersions[*].EngineVersion' \
  --output table
```

### S3 파라미터

```
variable "s3_buckets" {
  type = map(object({
    versioning_enabled = bool  # 버전 관리 활성화
    enable_encryption  = bool  # 서버 측 암호화 (AES256)
    lifecycle_rules = list(object({
      id                       = string  # 규칙 이름
      enabled                  = bool    # 규칙 활성화 여부
      expiration_days          = number  # 일 후 삭제
      transition_days          = number  # 일 후 전환
      transition_storage_class = string  # STANDARD_IA, GLACIER 등
    }))
  }))
  default = {}
}
```

### CloudWatch 파라미터

```
variable "log_retention_days" {
  description = "로그 보관 기간 (일)"
  type        = number
  default     = 7
  # 가능한 값: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
}
```

### SNS 파라미터

```
variable "sns_topic_name" {
  description = "SNS 토픽 이름"
  type        = string
  default     = "infrastructure-alerts"
}

variable "sns_email_endpoints" {
  description = "알림 수신 이메일 주소 목록"
  type        = list(string)
  default     = []
  # 예: ["admin@example.com", "oncall@example.com"]
}
```

### Lambda 파라미터

```
variable "lambda_functions" {
  type = map(object({
    runtime           = string           # python3.11, nodejs18.x, java17 등
    handler           = string           # lambda_function.handler
    source_code_path  = string           # ./lambda/function-name
    memory_size       = number           # MB (128 ~ 10240)
    timeout           = number           # 초 (최대 900)
    environment_vars  = map(string)      # 환경 변수
    enable_s3_access  = bool             # S3 접근 권한
    enable_vpc_access = bool             # VPC 내부 실행
  }))
  default = {}
}
```

---

## 연결된 인프라 생성 예시

### 예시 1: 웹 서버 + 데이터베이스 + 스토리지 (3-Tier Architecture)

**구성**: VPC → EC2 (Web) → RDS (MySQL) → S3 (Storage) + CloudWatch (Monitoring)[web:92]

**terraform.tfvars**:
```
project_name = "web-app"
environment  = "prod"
aws_region   = "ap-northeast-2"
key_name     = "my-key"

# 모든 서비스 활성화
enable_vpc        = true
enable_ec2        = true
enable_rds        = true
enable_s3         = true
enable_cloudwatch = true
enable_sns        = true

# VPC 설정
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["ap-northeast-2a", "ap-northeast-2c"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
enable_nat_gateway   = true

# EC2 웹 서버 (모든 연결 활성화)
ec2_instances = {
  "web-server-1" = {
    instance_type          = "t3.medium"
    ami_id                 = "ami-0c9c942bd7bf113a2"
    enable_s3_access       = true   # S3 업로드/다운로드
    enable_rds_access      = true   # DB 연결
    enable_cloudwatch_logs = true   # 로그 수집
  },
  "web-server-2" = {
    instance_type          = "t3.medium"
    ami_id                 = "ami-0c9c942bd7bf113a2"
    enable_s3_access       = true
    enable_rds_access      = true
    enable_cloudwatch_logs = true
  }
}

# RDS MySQL 데이터베이스
rds_instances = {
  "main-db" = {
    engine            = "mysql"
    engine_version    = "8.0.35"
    instance_class    = "db.t3.medium"
    allocated_storage = 100
    db_name           = "webapp"
    username          = "admin"
    password          = "YourSecurePassword123!"
    enable_s3_backup  = true  # S3로 백업
  }
}

# S3 스토리지
s3_buckets = {
  "user-uploads" = {
    versioning_enabled = true
    enable_encryption  = true
    lifecycle_rules = [
      {
        id                       = "archive-old-uploads"
        enabled                  = true
        expiration_days          = 365
        transition_days          = 90
        transition_storage_class = "GLACIER"
      }
    ]
  },
  "app-backups" = {
    versioning_enabled = true
    enable_encryption  = true
    lifecycle_rules    = []
  }
}

# CloudWatch 모니터링
log_retention_days = 30

# SNS 알림
sns_topic_name = "webapp-alerts"
sns_email_endpoints = ["devops@company.com"]
```

**실행 및 배포**:
```
# 1. 초기화
terraform init

# 2. 실행 계획 확인 (어떤 리소스가 생성되는지 확인)
terraform plan -out=tfplan

# 3. 단계별 생성 (안전)
# 단계 1: VPC 먼저
terraform apply -target=module.vpc

# 단계 2: S3와 CloudWatch (독립적)
terraform apply -target=module.s3 -target=module.cloudwatch

# 단계 3: RDS
terraform apply -target=module.rds

# 단계 4: EC2 (모든 연결 자동 설정)
terraform apply -target=module.ec2

# 단계 5: SNS
terraform apply -target=module.sns

# 또는 한번에 생성
terraform apply -auto-approve

# 4. 생성된 리소스 정보 확인
terraform output
```

**출력 결과**:
```
ec2_public_ip_web-server-1 = "13.125.123.45"
ec2_public_ip_web-server-2 = "13.125.123.46"
rds_endpoint_main-db = "webapp-prod-main-db.xxxxx.ap-northeast-2.rds.amazonaws.com:3306"
s3_bucket_name_user-uploads = "web-app-prod-user-uploads"
cloudwatch_log_group_name = "/aws/web-app/prod"
```

**EC2에서 RDS 연결 테스트**:
```
# EC2에 SSH 접속
ssh -i ~/.ssh/my-key.pem ec2-user@13.125.123.45

# RDS 연결 확인 (연결 정보는 /home/ec2-user/rds-connection.txt에 저장됨)
cat /home/ec2-user/rds-connection.txt

# MySQL 클라이언트 설치 및 연결
sudo yum install -y mysql
mysql -h webapp-prod-main-db.xxxxx.ap-northeast-2.rds.amazonaws.com \
      -u admin -p webapp

# S3 접근 테스트
aws s3 ls s3://web-app-prod-user-uploads/
echo "test" > test.txt
aws s3 cp test.txt s3://web-app-prod-user-uploads/

# CloudWatch 로그 확인
tail -f /var/log/messages
# 로그가 CloudWatch로 자동 전송됨
```

---

### 예시 2: 서버리스 데이터 파이프라인

**구성**: S3 (Input) → Lambda (Processing) → S3 (Output) + SNS (Notification)[web:89]

**terraform.tfvars**:
```
project_name = "data-pipeline"
environment  = "prod"
aws_region   = "ap-northeast-2"

enable_s3     = true
enable_lambda = true
enable_sns    = true

# S3 버킷
s3_buckets = {
  "input-data" = {
    versioning_enabled = true
    enable_encryption  = true
    lifecycle_rules    = []
  },
  "processed-data" = {
    versioning_enabled = true
    enable_encryption  = true
    lifecycle_rules = [
      {
        id                       = "archive-processed"
        enabled                  = true
        expiration_days          = 180
        transition_days          = 30
        transition_storage_class = "GLACIER"
      }
    ]
  }
}

# Lambda 함수 (S3 접근 가능)
lambda_functions = {
  "csv-processor" = {
    runtime          = "python3.11"
    handler          = "lambda_function.handler"
    source_code_path = "./lambda/csv-processor"
    memory_size      = 2048
    timeout          = 300
    environment_vars = {
      INPUT_BUCKET  = "data-pipeline-prod-input-data"
      OUTPUT_BUCKET = "data-pipeline-prod-processed-data"
    }
    enable_s3_access  = true
    enable_vpc_access = false
  },
  "data-validator" = {
    runtime          = "python3.11"
    handler          = "index.handler"
    source_code_path = "./lambda/validator"
    memory_size      = 1024
    timeout          = 120
    environment_vars = {
      SNS_TOPIC_ARN = "arn:aws:sns:ap-northeast-2:123456789012:data-pipeline-prod-alerts"
    }
    enable_s3_access  = true
    enable_vpc_access = false
  }
}

# SNS 알림
sns_topic_name = "data-pipeline-alerts"
sns_email_endpoints = ["data-team@company.com"]
```

**Lambda 함수 코드 준비**:
```
# CSV Processor Lambda
mkdir -p lambda/csv-processor
cat > lambda/csv-processor/lambda_function.py <<'EOF'
import json
import boto3
import os

s3 = boto3.client('s3')

def handler(event, context):
    input_bucket = os.environ['INPUT_BUCKET']
    output_bucket = os.environ['OUTPUT_BUCKET']
    
    # S3 이벤트에서 파일 정보 추출
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        
        print(f"Processing file: {key} from bucket: {bucket}")
        
        # 파일 다운로드
        obj = s3.get_object(Bucket=bucket, Key=key)
        data = obj['Body'].read().decode('utf-8')
        
        # 데이터 처리 (예시)
        processed_data = data.upper()
        
        # 결과 업로드
        output_key = f"processed/{key}"
        s3.put_object(
            Bucket=output_bucket,
            Key=output_key,
            Body=processed_data
        )
        
        print(f"Processed file saved to: {output_key}")
    
    return {
        'statusCode': 200,
        'body': json.dumps('Processing complete')
    }
EOF

# Validator Lambda
mkdir -p lambda/validator
cat > lambda/validator/index.py <<'EOF'
import json
import boto3
import os

sns = boto3.client('sns')

def handler(event, context):
    sns_topic = os.environ['SNS_TOPIC_ARN']
    
    # 검증 로직 (예시)
    is_valid = True
    
    if is_valid:
        message = "Data validation passed"
    else:
        message = "Data validation failed"
        # SNS 알림 전송
        sns.publish(
            TopicArn=sns_topic,
            Subject='Data Validation Alert',
            Message=message
        )
    
    return {
        'statusCode': 200,
        'body': json.dumps(message)
    }
EOF
```

**실행**:
```
terraform init
terraform apply

# S3 이벤트 트리거 설정 (수동)
aws s3api put-bucket-notification-configuration \
  --bucket data-pipeline-prod-input-data \
  --notification-configuration '{
    "LambdaFunctionConfigurations": [{
      "LambdaFunctionArn": "arn:aws:lambda:ap-northeast-2:123456789012:function:data-pipeline-prod-csv-processor",
      "Events": ["s3:ObjectCreated:*"]
    }]
  }'

# 테스트
echo "test,data,123" > test.csv
aws s3 cp test.csv s3://data-pipeline-prod-input-data/

# 처리 결과 확인
aws s3 ls s3://data-pipeline-prod-processed-data/processed/
```

---

### 예시 3: 고가용성 API 서버 (Multi-AZ)

**구성**: VPC (3 AZ) → EC2 (3대) → RDS (Multi-AZ) + CloudWatch + SNS[web:13]

**terraform.tfvars**:
```
project_name = "api-service"
environment  = "prod"
aws_region   = "ap-northeast-2"
key_name     = "api-key"

enable_vpc        = true
enable_ec2        = true
enable_rds        = true
enable_cloudwatch = true
enable_sns        = true

# VPC - 3개 가용 영역
vpc_cidr = "10.10.0.0/16"
availability_zones = [
  "ap-northeast-2a",
  "ap-northeast-2b",
  "ap-northeast-2c"
]
public_subnet_cidrs = [
  "10.10.1.0/24",
  "10.10.2.0/24",
  "10.10.3.0/24"
]
private_subnet_cidrs = [
  "10.10.11.0/24",
  "10.10.12.0/24",
  "10.10.13.0/24"
]
enable_nat_gateway = true

# EC2 - 각 AZ에 1대씩
ec2_instances = {
  "api-server-az1" = {
    instance_type          = "t3.large"
    ami_id                 = "ami-0c9c942bd7bf113a2"
    enable_s3_access       = false
    enable_rds_access      = true
    enable_cloudwatch_logs = true
  },
  "api-server-az2" = {
    instance_type          = "t3.large"
    ami_id                 = "ami-0c9c942bd7bf113a2"
    enable_s3_access       = false
    enable_rds_access      = true
    enable_cloudwatch_logs = true
  },
  "api-server-az3" = {
    instance_type          = "t3.large"
    ami_id                 = "ami-0c9c942bd7bf113a2"
    enable_s3_access       = false
    enable_rds_access      = true
    enable_cloudwatch_logs = true
  }
}

# RDS - 프로덕션 설정
rds_instances = {
  "api-db" = {
    engine            = "postgres"
    engine_version    = "15.3"
    instance_class    = "db.r5.xlarge"
    allocated_storage = 200
    db_name           = "apidb"
    username          = "dbadmin"
    password          = "VerySecurePassword123!"
    enable_s3_backup  = false
  }
}

# CloudWatch
log_retention_days = 90

# SNS
sns_topic_name = "api-service-alerts"
sns_email_endpoints = [
  "sre@company.com",
  "oncall@company.com"
]
```

**실행 및 로드 밸런서 추가** (선택사항):
```
terraform apply

# 생성된 EC2 IP 확인
terraform output | grep ec2_public_ip

# 수동으로 ALB 추가 (Terraform 외부)
aws elbv2 create-load-balancer \
  --name api-service-alb \
  --subnets subnet-xxx subnet-yyy subnet-zzz \
  --security-groups sg-xxxxx
```

---

## 고급 사용법

### 1. 특정 리소스만 생성/삭제

```
# S3 버킷 1개만 생성
terraform apply -target='module.s3["user-uploads"]'

# EC2 인스턴스 1대만 생성
terraform apply -target='module.ec2["web-server-1"]'

# RDS 1개만 삭제
terraform destroy -target='module.rds["analytics-db"]'

# CloudWatch만 업데이트
terraform apply -target=module.cloudwatch
```

### 2. 변수 파일 분리 관리

```
# 환경별 변수 파일 생성
terraform-infra-builder/
├── environments/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars

# Dev 환경 배포
terraform apply -var-file=environments/dev.tfvars

# Prod 환경 배포
terraform apply -var-file=environments/prod.tfvars
```

**dev.tfvars**:
```
project_name = "myapp"
environment  = "dev"
enable_vpc   = true
enable_ec2   = true

ec2_instances = {
  "dev-server" = {
    instance_type          = "t3.small"  # 개발은 작은 인스턴스
    ami_id                 = "ami-0c9c942bd7bf113a2"
    enable_s3_access       = true
    enable_rds_access      = false
    enable_cloudwatch_logs = false
  }
}
```

**prod.tfvars**:
```
project_name = "myapp"
environment  = "prod"
enable_vpc   = true
enable_ec2   = true

ec2_instances = {
  "prod-server-1" = {
    instance_type          = "t3.large"  # 프로덕션은 큰 인스턴스
    ami_id                 = "ami-0c9c942bd7bf113a2"
    enable_s3_access       = true
    enable_rds_access      = true
    enable_cloudwatch_logs = true
  },
  "prod-server-2" = {
    instance_type          = "t3.large"
    ami_id                 = "ami-0c9c942bd7bf113a2"
    enable_s3_access       = true
    enable_rds_access      = true
    enable_cloudwatch_logs = true
  }
}
```

### 3. State 파일 원격 저장 (팀 협업)

**backend.tf** 생성:
```
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "infrastructure/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }
}
```

**S3 버킷 및 DynamoDB 테이블 생성**:
```
# S3 버킷 생성
aws s3api create-bucket \
  --bucket my-terraform-state-bucket \
  --region ap-northeast-2 \
  --create-bucket-configuration LocationConstraint=ap-northeast-2

# 버킷 버저닝 활성화
aws s3api put-bucket-versioning \
  --bucket my-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# DynamoDB 락 테이블 생성
aws dynamodb create-table \
  --table-name terraform-lock-table \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-northeast-2

# State 마이그레이션
terraform init -migrate-state
```

### 4. 리소스 Import (기존 리소스 가져오기)

```
# 기존 S3 버킷 가져오기
terraform import 'module.s3["existing-bucket"].aws_s3_bucket.this' existing-bucket-name

# 기존 EC2 인스턴스 가져오기
terraform import 'module.ec2["imported-server"].aws_instance.this' i-1234567890abcdef0

# 기존 VPC 가져오기
terraform import 'module.vpc.aws_vpc.this' vpc-0a1b2c3d
```

### 5. Output 값 조회 및 활용

```
# 모든 출력 값 조회
terraform output

# 특정 출력 값만 조회
terraform output ec2_public_ip_web-server-1

# JSON 형식으로 조회
terraform output -json

# 다른 스크립트에서 사용
WEB_SERVER_IP=$(terraform output -raw ec2_public_ip_web-server-1)
echo "Web server IP: $WEB_SERVER_IP"

# 출력 값으로 SSH 접속
ssh -i ~/.ssh/my-key.pem ec2-user@$(terraform output -raw ec2_public_ip_web-server-1)
```

---

## 트러블슈팅

### 문제 1: "Error: Error launching source instance"

**원인**: AMI ID가 해당 리전에 존재하지 않음

**해결**:
```
# 현재 리전의 Amazon Linux 2023 AMI 조회
aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-*-x86_64" \
  --region ap-northeast-2 \
  --query 'Images.ImageId' \
  --output text

# terraform.tfvars에 올바른 AMI ID 입력
```

### 문제 2: "Error creating DB Instance: InvalidVPCNetworkStateFault"

**원인**: Private Subnet에 라우팅이 없거나 서브넷 개수 부족

**해결**:
```
# 최소 2개의 다른 가용 영역 서브넷 필요
private_subnet_cidrs = [
  "10.0.11.0/24",  # AZ-a
  "10.0.12.0/24"   # AZ-c
]

# NAT Gateway 활성화
enable_nat_gateway = true
```

### 문제 3: EC2에서 RDS 연결 실패

**원인**: Security Group 규칙이 제대로 설정되지 않음

**확인**:
```
# RDS Security Group Inbound 규칙 확인
aws ec2 describe-security-groups \
  --group-ids sg-xxxxx \
  --query 'SecurityGroups.IpPermissions'

# EC2에서 연결 테스트
telnet <rds-endpoint> 3306
```

**해결**:
```
# terraform.tfvars에서 활성화 확인
ec2_instances = {
  "web-server" = {
    enable_rds_access = true  # ← 이 설정 확인
  }
}
```

### 문제 4: CloudWatch 로그가 수집되지 않음

**원인**: CloudWatch Agent가 설치되지 않았거나 IAM 권한 부족

**확인**:
```
# EC2에 SSH 접속
ssh -i ~/.ssh/my-key.pem ec2-user@<ec2-ip>

# CloudWatch Agent 상태 확인
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a query -m ec2 -c default

# Agent 로그 확인
sudo tail -f /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log

# 수동으로 재시작
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json
```

### 문제 5: Terraform state 잠김 오류

**원인**: 이전 실행이 중단되어 state가 잠김

**해결**:
```
# Lock 정보 확인
terraform force-unlock <LOCK_ID>

# 또는 DynamoDB에서 직접 삭제 (S3 backend 사용 시)
aws dynamodb delete-item \
  --table-name terraform-lock-table \
  --key '{"LockID":{"S":"my-terraform-state-bucket/infrastructure/terraform.tfstate"}}'
```

### 문제 6: "Error: Insufficient capacity" (EC2 인스턴스 생성 실패)

**원인**: 해당 AZ에 선택한 인스턴스 타입 용량 부족

**해결**:
```
# 다른 가용 영역 시도
availability_zones = [
  "ap-northeast-2b",  # 다른 AZ로 변경
  "ap-northeast-2c"
]

# 또는 다른 인스턴스 타입 선택
instance_type = "t3.medium"  # t3.large 대신
```

### 문제 7: S3 버킷 이름 충돌

**원인**: S3 버킷 이름은 전 세계적으로 고유해야 함

**해결**:
```
# 프로젝트 이름과 환경을 포함하여 고유성 보장
# 버킷 이름: {project_name}-{environment}-{bucket_name}
project_name = "mycompany-webapp"  # 회사명 포함
environment  = "prod"

s3_buckets = {
  "data-storage-20250121" = {  # 날짜 추가
    versioning_enabled = true
    enable_encryption  = true
  }
}
```

---

## 명령어 치트시트

```
# 기본 작업 흐름
terraform init              # 초기화
terraform validate          # 구성 검증
terraform plan              # 실행 계획 확인
terraform apply             # 인프라 생성
terraform destroy           # 인프라 삭제

# 특정 타겟 작업
terraform apply -target=MODULE.RESOURCE     # 특정 리소스만 생성
terraform destroy -target=MODULE.RESOURCE   # 특정 리소스만 삭제

# 변수 파일 사용
terraform apply -var-file=prod.tfvars       # 파일에서 변수 로드
terraform apply -var="key=value"            # 명령줄에서 변수 전달

# Output 조회
terraform output                            # 모든 출력 조회
terraform output VARIABLE_NAME              # 특정 출력만 조회
terraform output -json                      # JSON 형식

# State 관리
terraform state list                        # State의 모든 리소스 목록
terraform state show MODULE.RESOURCE        # 리소스 상세 정보
terraform state rm MODULE.RESOURCE          # State에서 제거
terraform import MODULE.RESOURCE ID         # 기존 리소스 가져오기

# 형식 및 유효성 검사
terraform fmt                               # 코드 포맷팅
terraform fmt -recursive                    # 하위 디렉토리 포함
terraform validate                          # 구문 검증

# Workspace 관리
terraform workspace list                    # Workspace 목록
terraform workspace new WORKSPACE_NAME      # 새 Workspace 생성
terraform workspace select WORKSPACE_NAME   # Workspace 선택

# 그래프 생성
terraform graph | dot -Tsvg > graph.svg     # 리소스 의존성 그래프
```

---

## 비용 예측

### 최소 구성 (S3만)
- **S3 Standard**: $0.025/GB/월
- **예상 비용**: ~$1-5/월

### 개발 환경 (VPC + EC2 + RDS)
- **VPC**: 무료
- **EC2 t3.small**: ~$15/월
- **RDS db.t3.micro**: ~$15/월
- **NAT Gateway**: ~$32/월
- **예상 비용**: ~$62/월

### 프로덕션 환경 (3-Tier)
- **EC2 t3.large (3대)**: ~$150/월
- **RDS db.r5.large**: ~$140/월
- **NAT Gateway (3개)**: ~$96/월
- **ALB**: ~$22/월
- **S3 + CloudWatch**: ~$10/월
- **예상 비용**: ~$418/월

**비용 계산기**: https://calculator.aws/

---

## 라이센스

MIT License

---

## 지원 및 기여

- 📧 이메일: support@example.com
- 🐛 이슈: [GitHub Issues](https://github.com/your-repo/issues)
- 📖 문서: [Wiki](https://github.com/your-repo/wiki)

---

## 참고 자료

- [Terraform 공식 문서](https://www.terraform.io/docs)
- [AWS Provider 문서](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
```

***

## examples/ 디렉토리 구조

각 예시별로 독립적인 디렉토리를 만들어 바로 테스트할 수 있도록 구성합니다.[2][1]

```
examples/
├── 01-s3-only/
│   ├── main.tf -> ../../main.tf
│   ├── variables.tf -> ../../variables.tf
│   └── terraform.tfvars
│
├── 02-vpc-ec2/
│   ├── main.tf -> ../../main.tf
│   ├── variables.tf -> ../../variables.tf
│   └── terraform.tfvars
│
├── 03-full-stack/
│   ├── main.tf -> ../../main.tf
│   ├── variables.tf -> ../../variables.tf
│   └── terraform.tfvars
│
└── 04-serverless/
    ├── main.tf -> ../../main.tf
    ├── variables.tf -> ../../variables.tf
    └── terraform.tfvars
```

각 예시는 심볼릭 링크로 루트 모듈을 참조하고, `terraform.tfvars`만 각각 다르게 설정하면 됩니다.[4][5]

이 README 문서를 통해 Terraform만으로도 모든 시나리오를 테스트하고 실제 인프라를 구축할 수 있습니다.[6][1][2]

[1](https://docs.cloud.google.com/docs/terraform/best-practices/general-style-structure)
[2](https://betterterraformpractices.com/getting-started/important-concepts/3readme-guide/)
[3](https://www.microtica.com/blog/terraform-modules-best-practices)
[4](https://spacelift.io/blog/terraform-tfvars)
[5](https://controlmonkey.io/resource/terraform-variables-guide/)
[6](https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices)
[7](https://arxiv.org/abs/2205.10676v1)
[8](http://arxiv.org/pdf/2203.13871.pdf)
[9](https://www.frontiersin.org/articles/10.3389/fspas.2021.789563/pdf)
[10](https://linkinghub.elsevier.com/retrieve/pii/S0306437924000802)
[11](https://arxiv.org/pdf/2312.03250.pdf)
[12](http://arxiv.org/pdf/2404.18515.pdf)
[13](http://arxiv.org/pdf/2412.00726.pdf)
[14](https://arxiv.org/pdf/2201.09015.pdf)
[15](https://velog.io/@bellship24/terraform-docs%EB%A1%9C-README.md-%EC%9E%90%EB%8F%99-%EC%9E%91%EC%84%B1%ED%95%98%EB%8A%94-%EB%B0%A9%EB%B2%95)
[16](https://discuss.hashicorp.com/t/readme-md-for-terraform-module/58748)
[17](https://docs.aws.amazon.com/prescriptive-guidance/latest/terraform-aws-provider-best-practices/structure.html)
[18](https://www.youtube.com/watch?v=B6l2UbCsH94)