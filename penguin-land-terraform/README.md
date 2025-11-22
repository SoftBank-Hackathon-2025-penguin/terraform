# Penguin-Land Terraform Project

Penguin-Land 프로젝트를 위한 Terraform 인프라 코드입니다. AWS 리소스 7종(VPC, EC2, S3, DynamoDB, Lambda, SNS, CloudWatch)을 원클릭으로 배포하고 관리합니다.

## 📋 프로젝트 개요

- **목적**: 테라폼 기반 원클릭 배포 및 이상 징후 코칭 서비스
- **지원 리소스**: VPC, EC2, S3, DynamoDB, Lambda, SNS, CloudWatch
- **특징**: 
  - 세션 ID 기반 리소스 격리
  - CloudWatch를 통한 실시간 모니터링
  - 게이미피케이션 기반 알림 시스템

## 🏗️ 생성되는 AWS 리소스

1. **VPC**: 네트워크 격리 (Public/Private Subnet, Internet Gateway, Route Table)
2. **EC2**: Spring Boot 애플리케이션 서버 (t2.micro, Amazon Linux 2)
3. **S3**: 정적 파일 저장 및 Terraform State 백엔드
4. **DynamoDB**: 애플리케이션 데이터 및 State Lock 관리
5. **Lambda**: CloudWatch 알람 처리 및 위험 점수 계산
6. **SNS**: 알람 알림 발송
7. **CloudWatch**: 로그 수집, 메트릭 모니터링, 알람 설정

## 📁 파일 구조

```
.
├── provider.tf           # Terraform 및 AWS Provider 설정
├── variables.tf          # 변수 정의
├── terraform.tfvars.example  # 변수 값 예시 파일
├── vpc.tf               # VPC 및 네트워크 리소스
├── iam.tf               # IAM Role 및 정책
├── ec2.tf               # EC2 인스턴스
├── s3.tf                # S3 버킷
├── dynamodb.tf          # DynamoDB 테이블
├── sns.tf               # SNS 토픽
├── lambda.tf            # Lambda 함수
├── cloudwatch.tf        # CloudWatch 알람 및 대시보드
├── outputs.tf           # 출력 값
├── backend.tf           # Terraform Backend 설정 (선택적)
└── lambda/
    └── alarm_processor.py  # Lambda 함수 코드
```

## 🚀 사용 방법

### 방법 1: Terraform Workspace 사용 (권장 - 다중 사용자)

Workspace를 사용하면 여러 사용자의 인프라를 독립적으로 관리할 수 있습니다.

#### 1.1 로컬 State 사용 (해커톤용 - 간편)

```bash
# 해커톤 프로젝트이므로 State는 로컬 파일로 관리됩니다
# S3 Backend 설정 불필요 - 바로 시작 가능!

# State 저장 위치 확인
# - 기본: ./terraform.tfstate
# - Workspace 사용: ./terraform.tfstate.d/user-001/terraform.tfstate
```

**장점:**
- ✅ 복잡한 Backend 설정 불필요
- ✅ 빠른 시작
- ✅ S3/DynamoDB 비용 절감

**주의사항:**
- ⚠️ State 파일 백업 권장 (중요한 변경 전)
- ⚠️ 여러 명이 동시 실행 시 충돌 가능

#### 1.2 Backend 초기화 (프로덕션 전환 시 선택사항)

프로덕션 환경으로 전환하려면:
```bash
# 공유 S3 버킷과 DynamoDB 테이블 생성
cd scripts
./bootstrap-backend.sh

# backend.tf 파일의 주석 해제 및 설정 업데이트
# 그 다음 terraform init -migrate-state 실행
```

#### 1.3 사용자 Workspace 생성 및 배포

```bash
# 방법 A: 자동화 스크립트 사용 (간편)
cd scripts
./manage-workspace.sh create user-001        # Workspace 생성
python3 generate_tfvars.py --user-id user-001 --email user@example.com  # 변수 파일 생성
./manage-workspace.sh deploy user-001        # 인프라 배포

# 방법 B: 수동 명령어
terraform workspace new user-001             # Workspace 생성
cp terraform.tfvars.example user-001.auto.tfvars
vi user-001.auto.tfvars                      # 변수 편집
terraform apply -var-file=user-001.auto.tfvars
```

#### 1.4 Workspace 관리

```bash
# Workspace 목록 확인
./manage-workspace.sh list

# 특정 Workspace 상태 확인
./manage-workspace.sh status user-001

# Workspace 전환
./manage-workspace.sh select user-002

# 리소스 삭제
./manage-workspace.sh destroy user-001

# Workspace 삭제 (리소스 삭제 후)
./manage-workspace.sh delete user-001
```

### 방법 2: 단일 사용자 배포 (간단)

Workspace 없이 단일 환경만 관리하는 경우:

#### 2.1 사전 요구사항

- Terraform >= 1.0
- AWS CLI 설정 및 인증 정보 구성
- 적절한 AWS 권한 (EC2, VPC, S3, DynamoDB, Lambda, SNS, CloudWatch)

#### 2.2 변수 설정

```bash
# terraform.tfvars.example을 복사하여 사용
cp terraform.tfvars.example terraform.tfvars

# terraform.tfvars 파일을 편집하여 필요한 값 설정
vi terraform.tfvars
```

필수 변수:
- `session_id`: 고유한 세션 ID (예: session-001)
- `aws_region`: AWS 리전 (기본값: ap-northeast-1)

선택적 변수:
- `ec2_key_name`: EC2 SSH 접속용 키페어 이름
- `alert_email`: 알람 수신용 이메일 주소

#### 2.3 인프라 배포

```bash
# Terraform 초기화
terraform init

# 실행 계획 확인
terraform plan

# 리소스 생성
terraform apply

# 출력 값 확인
terraform output
```

### 4. 주요 출력 값

배포 완료 후 다음 정보를 확인할 수 있습니다:

- `ec2_public_ip`: EC2 인스턴스의 공인 IP 주소
- `application_url`: Spring Boot 애플리케이션 접속 URL
- `cloudwatch_dashboard_url`: CloudWatch 대시보드 URL
- `deployment_summary`: 전체 배포 요약 정보

### 5. 리소스 삭제

```bash
# 모든 리소스 삭제
terraform destroy
```

## ⚙️ 모니터링 및 알람

### CPU 사용률 임계값
- **경고 (Warning)**: 50% 이상
- **위험 (Critical)**: 70% 이상

### 메모리 사용률 임계값
- **경고**: 80% 이상

### 디스크 사용률 임계값
- **경고**: 80% 이상

### 알람 처리
CloudWatch 알람이 발생하면:
1. SNS를 통해 Lambda 함수로 전달
2. Lambda가 위험 점수를 계산 (0-100)
3. DynamoDB에 메트릭 저장
4. 펭귄 상태 결정:
   - **안정 (0-30점)**: 😊 초록색
   - **주의 (31-70점)**: 😐 노란색
   - **위험 (71-100점)**: 😢 빨간색

## 🔒 보안 고려사항

- **최소 권한 원칙**: IAM Role은 필요한 최소한의 권한만 부여
- **암호화**: S3 버킷 및 EBS 볼륨 암호화 적용
- **네트워크 격리**: Public/Private Subnet 분리
- **보안 그룹**: 필요한 포트만 개방

## 📊 비용 추정

주요 리소스별 예상 비용 (도쿄 리전 기준):

- EC2 (t2.micro): ~$0.0152/시간
- S3: 사용량 기반
- DynamoDB: PAY_PER_REQUEST 모드
- Lambda: 호출 횟수 기반
- CloudWatch: 메트릭 및 알람 개수 기반
- SNS: 메시지 전송 횟수 기반

**참고**: 프리 티어 사용 시 상당 부분 무료로 사용 가능

## 🔧 커스터마이징

### EC2 인스턴스 타입 변경
```hcl
# terraform.tfvars
ec2_instance_type = "t2.small"  # 기본값: t2.micro
```

### 알람 임계값 조정
```hcl
# terraform.tfvars
cpu_warning_threshold = 60      # 기본값: 50
cpu_critical_threshold = 80     # 기본값: 70
```

### 리전 변경
```hcl
# terraform.tfvars
aws_region = "us-east-1"        # 기본값: ap-northeast-1
```

## 🐛 문제 해결

### 1. Terraform State Lock 에러
```bash
# DynamoDB Lock 테이블 확인
aws dynamodb describe-table --table-name penguin-land-SESSION_ID-tflock

# 강제로 Lock 해제 (주의: 다른 작업이 실행 중이 아닐 때만 사용)
terraform force-unlock LOCK_ID
```

### 2. Lambda 함수 배포 실패
```bash
# Lambda 코드 재패키징
cd lambda
zip -r alarm_processor.zip alarm_processor.py
cd ..

# Terraform 재적용
terraform apply
```

### 3. CloudWatch 에이전트 미작동
```bash
# EC2에 SSH 접속 후
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
```

## 📚 추가 참고사항

### Workspace 기반 아키텍처 (자세한 설명)

Workspace를 활용한 다중 사용자 관리에 대한 자세한 내용은 `WORKSPACE_GUIDE.md`를 참조하세요.

**주요 장점:**
- 각 사용자별 독립적인 State 관리
- 동시에 여러 사용자 환경 배포 가능
- State 충돌 방지
- 같은 Terraform 코드로 격리된 환경 생성

**State 저장 구조:**
```
s3://penguin-land-shared-tfstate/
├── env:/user-001/terraform.tfstate
├── env:/user-002/terraform.tfstate
└── env:/user-003/terraform.tfstate
```

### Backend 설정

Workspace 사용 시 모든 사용자가 공유하는 S3 버킷을 사용하지만, 각 workspace는 자동으로 별도의 state 파일을 가집니다:

1. `scripts/bootstrap-backend.sh` 실행하여 공유 버킷 생성
2. `backend.tf` 파일의 주석 해제
3. `terraform init` 실행

### 세션 격리

각 세션(또는 workspace)은 고유한 `session_id`를 가지며, 모든 리소스에 태그로 표시됩니다:
- 다른 세션과 리소스 충돌 방지
- 세션별 독립적인 관리 가능
- 비용 추적 용이
- AWS 콘솔에서 태그로 필터링 가능

## 📞 지원

문제가 발생하거나 질문이 있으시면 이슈를 등록해주세요.

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.
