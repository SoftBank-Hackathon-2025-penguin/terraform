
# Terraform 모듈형 AWS 인프라 구축 도구

프론트엔드에서 선택한 AWS 서비스를 조합하여 즉시 인프라를 프로비저닝하는 Terraform 프로젝트입니다. VPC, EC2, RDS, S3, Lambda, CloudWatch, SNS를 모듈 단위로 관리하며, 서비스 간 자동 연결과 즉시 로그 수집을 지원합니다.

## 📋 목차
- [지원 서비스](#지원-서비스)
- [프로젝트 구조](#프로젝트-구조)
- [사전 요구사항](#사전-요구사항)
- [빠른 시작](#빠른-시작)
- [개별 서비스 생성 방법](#개별-서비스-생성-방법)
- [다중 서비스 연결 시나리오](#다중-서비스-연결-시나리오)
- [파라미터 상세 설명](#파라미터-상세-설명)

---

## 🚀 지원 서비스

| 서비스 | 주요 기능 | 자동 연결 |
|--------|-----------|-----------|
| **VPC** | 퍼블릭/프라이빗 서브넷, NAT Gateway, 보안 그룹 | 모든 리소스의 네트워크 기반 |
| **EC2** | 자동 AMI 선택, CloudWatch Agent 사전 설치, IAM 역할 | VPC, S3, CloudWatch |
| **RDS** | MySQL/PostgreSQL, Multi-AZ, Enhanced Monitoring | VPC, CloudWatch |
| **S3** | 버전 관리, 암호화, 라이프사이클 정책 | EC2 IAM 권한 자동 부여 |
| **Lambda** | VPC 내 실행, 기본 함수 템플릿 제공 | VPC, CloudWatch Logs |
| **CloudWatch** | EC2/RDS 메트릭 수집, 대시보드, CPU 알람 | EC2, RDS, SNS |
| **SNS** | 이메일/SMS 알림, CloudWatch 알람 통합 | CloudWatch |

---

## 📂 프로젝트 구조

```
terraform-infra-builder/
├── main.tf                    # 모듈 호출 및 조건부 생성
├── variables.tf               # 전역 변수 및 각 서비스별 설정
├── outputs.tf                 # 생성된 리소스 정보 출력
├── terraform.tfvars          # 실제 설정값 (프론트엔드에서 생성)
├── versions.tf               # Terraform/Provider 버전
├── backend.tf                # 상태 파일 저장소 (미구현)
├── scripts/
│   └── init.sh               # 초기 설정 자동화 스크립트
└── modules/
    ├── vpc/                  # 네트워크 인프라
    ├── ec2/                  # 컴퓨팅 인스턴스 + IAM
    ├── rds/                  # 관계형 데이터베이스
    ├── s3/                   # 오브젝트 스토리지
    ├── lambda/               # 서버리스 함수 + 기본 템플릿
    ├── cloudwatch/           # 모니터링 및 알람
    └── sns/                  # 알림 서비스
```

---

## 🔧 사전 요구사항

1. **Terraform 설치** (>= 1.5.0)
   ```
   # macOS
   brew install terraform
   
   # Linux
   wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
   unzip terraform_1.5.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

2. **AWS CLI 설치 및 인증**
   ```
   aws configure
   # AWS Access Key ID, Secret Access Key, Region 입력
   ```

3. **필요한 AWS 권한**
   - EC2, VPC, RDS, S3, Lambda, CloudWatch, SNS, IAM 생성 권한

---

## ⚡ 빠른 시작

### 1. 프로젝트 초기화
```
# 저장소 클론
git clone <repository-url>
cd terraform-infra-builder

# 초기화 스크립트 실행 (terraform.tfvars 템플릿 생성)
bash scripts/init.sh
```

### 2. 설정 파일 수정
`terraform.tfvars` 파일에서 원하는 서비스 활성화 및 파라미터 설정:
```
project_name = "my-project"
environment  = "dev"

# 생성할 서비스 선택
enable_vpc        = true
enable_ec2        = true
enable_rds        = false
enable_s3         = false
enable_cloudwatch = true
```

### 3. 인프라 생성
```
# 실행 계획 확인
terraform plan

# 인프라 배포
terraform apply

# 출력된 정보 확인
terraform output
```

### 4. 인프라 삭제
```
terraform destroy
```

---

## 🔨 개별 서비스 생성 방법

### VPC 단독 생성
VPC는 다른 서비스(EC2, RDS, Lambda)의 네트워크 기반이므로 독립 생성 가능합니다.

**terraform.tfvars:**
```
enable_vpc = true

vpc_config = {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  availability_zones   = ["ap-northeast-2a", "ap-northeast-2c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]
}
```

**출력 정보:**
- `vpc_id`: VPC 식별자
- `public_subnet_ids`: 퍼블릭 서브넷 목록 (EC2 배치 가능)
- `private_subnet_ids`: 프라이빗 서브넷 목록 (RDS, Lambda 배치)
- `nat_gateway_ids`: NAT Gateway 식별자

---

### EC2 생성 (VPC 필수)
EC2는 네트워크가 필요하므로 **VPC가 활성화되어야 합니다**.

**terraform.tfvars:**
```
enable_vpc = true
enable_ec2 = true

ec2_config = {
  instance_type = "t3.micro"        # 인스턴스 크기
  ami_id        = ""                # 비워두면 최신 Amazon Linux 2023 자동 선택
  key_name      = ""                # SSH 키 (SSM 사용 시 불필요)
  volume_size   = 20                # 루트 디스크 크기 (GB)
}
```

**생성되는 리소스:**
- EC2 인스턴스 (자동 AMI 선택)
- 보안 그룹 (SSH, HTTP, HTTPS 오픈)
- IAM 역할 (SSM, CloudWatch, S3 접근 권한)
- CloudWatch Agent 사전 설치 (메모리/디스크 메트릭 수집)

**접속 방법:**
```
# AWS Systems Manager Session Manager로 접속 (SSH 키 불필요)
aws ssm start-session --target <instance-id>
```

---

### RDS 생성 (VPC 권장)
RDS는 VPC 없이도 생성 가능하지만, **VPC 내 프라이빗 서브넷 배치를 강력히 권장**합니다.

**terraform.tfvars:**
```
enable_vpc = true
enable_rds = true

rds_config = {
  engine              = "mysql"               # mysql 또는 postgres
  engine_version      = "8.0"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20                    # 초기 스토리지 (GB)
  db_name             = "mydb"
  username            = "admin"
  password            = "SecurePassword123!"  # ⚠️ 실제 환경에선 AWS Secrets Manager 사용 권장
  multi_az            = false                 # 고가용성 필요 시 true
  skip_final_snapshot = true                  # 삭제 시 스냅샷 생성 여부
}
```

**출력 정보:**
- `db_endpoint`: 데이터베이스 접속 주소 (예: `mydb.xxxx.ap-northeast-2.rds.amazonaws.com:3306`)
- `db_port`: 포트 번호 (MySQL: 3306, PostgreSQL: 5432)

**연결 테스트 (EC2에서):**
```
mysql -h <db_endpoint> -u admin -p
# 비밀번호 입력 후 접속 확인
```

---

### S3 생성 (완전 독립)
S3는 리전 단위 서비스로 VPC 없이 독립적으로 생성 가능합니다.

**terraform.tfvars:**
```
enable_s3 = true

s3_config = {
  bucket_name       = "my-unique-bucket-name-12345"  # 전역적으로 고유해야 함
  enable_versioning = true                           # 파일 버전 관리
  enable_encryption = true                           # 기본 AES256 암호화
  lifecycle_rules   = false                          # 30일→IA, 90일→Glacier 자동 전환
}
```

**사용 예시 (EC2에서):**
```
# IAM 역할이 자동 부여되어 있으므로 즉시 사용 가능
aws s3 cp myfile.txt s3://my-unique-bucket-name-12345/
aws s3 ls s3://my-unique-bucket-name-12345/
```

---

### Lambda 생성 (VPC 선택)
Lambda는 VPC 외부 실행(기본) 또는 VPC 내부 실행(RDS 접근 필요 시) 모두 지원합니다.

**terraform.tfvars:**
```
enable_lambda = true

lambda_config = {
  function_name = "my-lambda-function"
  runtime       = "python3.11"                       # python3.11, nodejs18.x 등
  handler       = "lambda_function.lambda_handler"
  memory_size   = 128                                # MB
  timeout       = 30                                 # 초
  source_file   = ""                                 # 비워두면 기본 템플릿 사용
}
```

**기본 함수 동작:**
모듈에 포함된 `default_lambda.py`가 자동 배포되며, 간단한 Hello World 응답을 반환합니다.

**테스트:**
```
aws lambda invoke --function-name my-lambda-function output.json
cat output.json
```

---

### CloudWatch 생성 (EC2/RDS 모니터링)
CloudWatch는 독립 생성 가능하지만, **EC2 또는 RDS와 함께 사용할 때 의미**가 있습니다.

**terraform.tfvars:**
```
enable_vpc        = true
enable_ec2        = true
enable_cloudwatch = true

cloudwatch_config = {
  create_dashboard  = true
  alarm_email      = "admin@example.com"  # 알람 수신 이메일
  cpu_threshold    = 80                   # CPU 사용률 임계값 (%)
  memory_threshold = 80                   # 메모리 사용률 임계값 (%)
}
```

**생성되는 리소스:**
- CloudWatch 대시보드 (EC2/RDS CPU 메트릭 시각화)
- CPU 알람 (임계값 초과 시 SNS 알림)
- EC2 CloudWatch Logs 그룹 (`/aws/ec2/<instance-id>`)

---

### SNS 생성 (CloudWatch 알람용)
SNS는 독립 생성 가능하지만, **CloudWatch와 함께 사용 시 알람 전송**이 가능합니다.

**terraform.tfvars:**
```
enable_sns = true

sns_config = {
  topic_name      = "infra-alerts"
  display_name    = "Infrastructure Alerts"
  email_endpoints = ["admin@example.com", "team@example.com"]
  sms_endpoints   = ["+821012345678"]  # 국제 형식
}
```

**주의사항:**
- 이메일 구독은 AWS가 자동으로 확인 메일을 발송하므로 **이메일 승인 필요**
- SMS는 추가 비용 발생

---

## 🔗 다중 서비스 연결 시나리오

### 시나리오 1: EC2 + RDS 연결
**목적:** 웹 애플리케이션 서버(EC2)가 MySQL 데이터베이스(RDS)에 접근

**terraform.tfvars:**
```
enable_vpc = true
enable_ec2 = true
enable_rds = true

vpc_config = {
  cidr_block           = "10.0.0.0/16"
  availability_zones   = ["ap-northeast-2a", "ap-northeast-2c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]      # EC2 배치
  private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]  # RDS 배치
}

ec2_config = {
  instance_type = "t3.small"
  ami_id        = ""
  key_name      = "my-keypair"
  volume_size   = 30
}

rds_config = {
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  db_name           = "appdb"
  username          = "dbadmin"
  password          = "ChangeMe!2024"
  multi_az          = false
}
```

**동작 방식:**
1. VPC 내부에서 EC2(퍼블릭 서브넷)와 RDS(프라이빗 서브넷)가 동일 보안 그룹에 속함
2. RDS 보안 그룹은 VPC CIDR 블록에서 3306 포트 접근 허용
3. EC2에서 RDS 엔드포인트로 직접 접속 가능

**접속 테스트:**
```
# EC2 인스턴스에서 실행
mysql -h <rds_endpoint> -u dbadmin -p
# 비밀번호 입력
```

---

### 시나리오 2: EC2 + S3 연결
**목적:** EC2 인스턴스에서 S3 버킷에 파일 업로드/다운로드 (IAM 역할 기반 인증)

**terraform.tfvars:**
```
enable_vpc = true
enable_ec2 = true
enable_s3  = true

ec2_config = {
  instance_type = "t3.micro"
  ami_id        = ""
  key_name      = ""
  volume_size   = 20
}

s3_config = {
  bucket_name       = "my-app-storage-bucket-2024"
  enable_versioning = true
  enable_encryption = true
  lifecycle_rules   = false
}
```

**동작 방식:**
1. EC2 모듈의 `iam.tf`에서 S3 접근 권한을 가진 IAM 역할 자동 생성
2. IAM 정책은 `${project_name}-*` 패턴의 모든 S3 버킷에 대해 읽기/쓰기 허용
3. EC2 인스턴스 프로파일에 역할이 자동 연결되어 AWS CLI 사용 시 자격 증명 불필요

**사용 예시:**
```
# EC2 인스턴스에서 실행 (별도 인증 없이 작동)
echo "Hello S3" > test.txt
aws s3 cp test.txt s3://my-app-storage-bucket-2024/
aws s3 ls s3://my-app-storage-bucket-2024/
```

---

### 시나리오 3: EC2 + RDS + S3 + CloudWatch
**목적:** 전체 스택 모니터링 (웹 서버 + DB + 파일 스토리지 + 로그/알람)

**terraform.tfvars:**
```
enable_vpc        = true
enable_ec2        = true
enable_rds        = true
enable_s3         = true
enable_cloudwatch = true
enable_sns        = true

# ... (VPC, EC2, RDS, S3 설정 동일) ...

cloudwatch_config = {
  create_dashboard  = true
  alarm_email      = "devops@example.com"
  cpu_threshold    = 70
  memory_threshold = 75
}

sns_config = {
  topic_name      = "production-alerts"
  display_name    = "Production Alerts"
  email_endpoints = ["devops@example.com"]
}
```

**동작 방식:**
1. **EC2**: 시작 시 `userdata.sh`가 CloudWatch Agent 설치 및 활성화 → 메모리/디스크 메트릭 수집
2. **RDS**: Enhanced Monitoring 활성화 (60초 간격) → OS 수준 메트릭 수집
3. **CloudWatch**: EC2/RDS CPU 메트릭을 대시보드에 표시, 임계값 초과 시 SNS로 알람 전송
4. **SNS**: 이메일로 알람 수신 (구독 승인 후)

**확인 방법:**
```
# AWS Console
1. CloudWatch → Dashboards → "<project-name>-<env>-dashboard"
2. CloudWatch → Alarms → CPU 알람 상태 확인
3. SNS → Subscriptions → 이메일 구독 확인

# EC2 로그 확인
aws logs tail /aws/ec2/<instance-id> --follow
```

---

### 시나리오 4: Lambda + RDS 연결 (VPC 내부)
**목적:** Lambda 함수가 RDS 데이터베이스에 직접 접근

**terraform.tfvars:**
```
enable_vpc    = true
enable_rds    = true
enable_lambda = true

# Lambda가 VPC 내부에서 실행되도록 설정 (main.tf에서 자동 처리)
lambda_config = {
  function_name = "db-query-function"
  runtime       = "python3.11"
  handler       = "index.handler"
  memory_size   = 256
  timeout       = 60
  source_file   = "/path/to/your/lambda.py"  # RDS 연결 코드 포함
}
```

**Lambda 함수 예시 (`lambda.py`):**
```
import pymysql
import os

def handler(event, context):
    conn = pymysql.connect(
        host=os.environ['DB_HOST'],
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD'],
        database=os.environ['DB_NAME']
    )
    cursor = conn.cursor()
    cursor.execute("SELECT VERSION()")
    result = cursor.fetchone()
    conn.close()
    
    return {'statusCode': 200, 'body': str(result)}
```

**주의사항:**
- Lambda가 VPC 내부에서 실행되면 **Cold Start 시간 증가** (ENI 생성 시간)
- RDS 보안 그룹이 Lambda 보안 그룹에서 접근 허용해야 함
- Lambda 환경 변수에 DB 접속 정보 전달 필요 (`variables.tf`에 추가)

---

## 📖 파라미터 상세 설명

### 전역 파라미터

| 변수 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `project_name` | string | 필수 | 리소스 이름 접두사 (예: `myapp` → `myapp-dev-ec2`) |
| `environment` | string | `"dev"` | 환경 구분 (dev, staging, prod) |
| `aws_region` | string | `"ap-northeast-2"` | AWS 리전 (서울) |
| `common_tags` | map(string) | `{}` | 모든 리소스에 적용할 태그 |

---

### VPC 파라미터 (`vpc_config`)

| 변수 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `cidr_block` | string | `"10.0.0.0/16"` | VPC IP 대역 (65,536개 IP) |
| `enable_dns_hostnames` | bool | `true` | DNS 호스트네임 활성화 (RDS 필수) |
| `enable_dns_support` | bool | `true` | DNS 해석 활성화 |
| `availability_zones` | list(string) | `["ap-northeast-2a", "ap-northeast-2c"]` | 가용 영역 (Multi-AZ 지원) |
| `public_subnet_cidrs` | list(string) | `["10.0.1.0/24", "10.0.2.0/24"]` | 퍼블릭 서브넷 CIDR (각 256개 IP) |
| `private_subnet_cidrs` | list(string) | `["10.0.101.0/24", "10.0.102.0/24"]` | 프라이빗 서브넷 CIDR |

**생성되는 추가 리소스:**
- 인터넷 게이트웨이 (IGW)
- NAT 게이트웨이 (각 AZ별 1개)
- 라우트 테이블 (퍼블릭 1개, 프라이빗 AZ별 1개)
- 기본 보안 그룹 (VPC 내부 통신 허용)

---

### EC2 파라미터 (`ec2_config`)

| 변수 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `instance_type` | string | `"t3.micro"` | 인스턴스 크기 (t3.micro: 2 vCPU, 1GB RAM) |
| `ami_id` | string | `""` | AMI ID (비워두면 최신 Amazon Linux 2023 자동 선택) |
| `key_name` | string | `""` | SSH 키 페어 이름 (SSM 사용 시 불필요) |
| `volume_size` | number | `20` | 루트 볼륨 크기 (GB) |
| `allocate_eip` | bool | `false` | Elastic IP 할당 여부 (고정 IP 필요 시) |

**자동 설정:**
- 보안 그룹: SSH(22), HTTP(80), HTTPS(443) 포트 오픈
- IAM 역할: SSM, CloudWatch, S3 접근 권한
- CloudWatch Agent: 메모리/디스크 메트릭 수집 (60초 간격)
- 메타데이터 v2 강제 (IMDSv2)

---

### RDS 파라미터 (`rds_config`)

| 변수 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `engine` | string | `"mysql"` | DB 엔진 (`mysql` 또는 `postgres`) |
| `engine_version` | string | `"8.0"` | 엔진 버전 (MySQL 8.0, PostgreSQL 14 등) |
| `instance_class` | string | `"db.t3.micro"` | 인스턴스 크기 (2 vCPU, 1GB RAM) |
| `allocated_storage` | number | `20` | 초기 스토리지 (GB, 자동 확장 가능) |
| `db_name` | string | `"mydb"` | 기본 데이터베이스 이름 |
| `username` | string | `"admin"` | 마스터 사용자 이름 |
| `password` | string | 필수 | 마스터 비밀번호 (8자 이상, 특수문자 포함) |
| `multi_az` | bool | `false` | Multi-AZ 배포 (고가용성, 비용 2배) |
| `skip_final_snapshot` | bool | `true` | 삭제 시 최종 스냅샷 생략 (운영 환경은 false 권장) |
| `backup_retention_period` | number | `7` | 백업 보존 기간 (일) |
| `backup_window` | string | `"03:00-04:00"` | 백업 시간대 (UTC) |
| `maintenance_window` | string | `"mon:04:00-mon:05:00"` | 유지보수 시간대 (UTC) |

**자동 설정:**
- 보안 그룹: VPC CIDR에서 DB 포트 접근 허용
- Enhanced Monitoring: 60초 간격 OS 메트릭 수집
- CloudWatch Logs: 에러/슬로우 쿼리 로그 자동 전송
- 스토리지 암호화 (gp3 타입)

---

### S3 파라미터 (`s3_config`)

| 변수 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `bucket_name` | string | 필수 | 버킷 이름 (전역적으로 고유해야 함) |
| `enable_versioning` | bool | `true` | 파일 버전 관리 활성화 |
| `enable_encryption` | bool | `true` | AES256 서버 측 암호화 |
| `lifecycle_rules` | bool | `false` | 라이프사이클 규칙 (30일→IA, 90일→Glacier, 365일 삭제) |
| `enable_cors` | bool | `false` | CORS 설정 (웹 애플리케이션 필요 시) |

**보안 설정:**
- 퍼블릭 액세스 완전 차단
- HTTPS 전송 강제
- 버킷 정책 자동 적용

---

### Lambda 파라미터 (`lambda_config`)

| 변수 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `function_name` | string | 필수 | Lambda 함수 이름 |
| `runtime` | string | `"python3.11"` | 런타임 (python3.11, nodejs18.x, java17 등) |
| `handler` | string | `"lambda_function.lambda_handler"` | 핸들러 함수 경로 |
| `memory_size` | number | `128` | 메모리 할당 (MB, 128~10,240) |
| `timeout` | number | `30` | 타임아웃 (초, 최대 900초) |
| `source_file` | string | `""` | 소스 코드 경로 (비워두면 기본 템플릿 사용) |
| `environment_variables` | map(string) | `{}` | 환경 변수 (DB 접속 정보 등) |
| `log_retention_days` | number | `7` | CloudWatch Logs 보존 기간 (일) |

**VPC 내 실행:**
- `enable_vpc=true`일 경우 자동으로 프라이빗 서브넷 배치
- IAM 역할에 `AWSLambdaVPCAccessExecutionRole` 자동 추가

---

### CloudWatch 파라미터 (`cloudwatch_config`)

| 변수 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `create_dashboard` | bool | `true` | 대시보드 생성 여부 |
| `alarm_email` | string | `""` | 알람 수신 이메일 (SNS 활성화 시 필요) |
| `cpu_threshold` | number | `80` | CPU 사용률 임계값 (%) |
| `memory_threshold` | number | `80` | 메모리 사용률 임계값 (%) |

**모니터링 대상:**
- EC2: CPU, 메모리, 디스크 사용률
- RDS: CPU, 연결 수, 스토리지 사용률

---

### SNS 파라미터 (`sns_config`)

| 변수 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `topic_name` | string | 필수 | SNS 토픽 이름 |
| `display_name` | string | `""` | 표시 이름 (SMS 발신자 이름) |
| `email_endpoints` | list(string) | `[]` | 이메일 구독자 목록 (확인 메일 승인 필요) |
| `sms_endpoints` | list(string) | `[]` | SMS 구독자 목록 (국제 형식: +821012345678) |

**자동 설정:**
- CloudWatch 알람이 SNS 토픽에 메시지 발행 권한 부여

---

## 📚 추가 리소스

### 유용한 명령어
```
# 특정 모듈만 계획 확인
terraform plan -target=module.ec2

# 특정 모듈만 배포
terraform apply -target=module.vpc -target=module.ec2

# 상태 확인
terraform state list
terraform state show module.ec2.aws_instance.main

# 출력 값만 확인
terraform output
terraform output -json > outputs.json

# 리소스 강제 재생성
terraform taint module.ec2.aws_instance.main
terraform apply
```

### 트러블슈팅
**문제 1: AMI를 찾을 수 없음**
```
# 해결: ami_id를 직접 지정
aws ec2 describe-images --owners amazon \
  --filters "Name=name,Values=al2023-ami-*-x86_64" \
  --query "Images | sort_by(@, &CreationDate) | [-1].ImageId"
```

**문제 2: RDS 비밀번호 오류**
- 최소 8자, 대소문자/숫자/특수문자 포함 필수
- 예: `MySecurePass123!`

**문제 3: S3 버킷 이름 중복**
- 전역적으로 고유해야 함
- 타임스탬프 추가: `my-bucket-${timestamp()}`

---

## 🛡️ 보안 권장사항

1. **RDS 비밀번호**: `terraform.tfvars` 대신 AWS Secrets Manager 사용
2. **SSH 키**: 가능한 한 AWS Systems Manager Session Manager 사용
3. **보안 그룹**: 운영 환경에선 SSH 포트를 관리자 IP로 제한
4. **IAM 역할**: 최소 권한 원칙 (S3 접근을 특정 버킷으로 제한)
5. **백업**: RDS `skip_final_snapshot=false`, S3 버전 관리 활성화

---

## 📞 문의 및 기여

- **이슈 제보**: GitHub Issues
- **기능 제안**: Pull Request 환영
- **문의**: devops@example.com

---

## 📄 라이선스

MIT License - 자유롭게 사용 및 수정 가능
