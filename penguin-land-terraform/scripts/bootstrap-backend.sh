#!/bin/bash
# ===================================================================
# Terraform Backend 초기화 스크립트
# ===================================================================
# 모든 workspace가 공유하는 S3 버킷과 DynamoDB Lock 테이블을 생성합니다.
# 
# 생성 리소스:
#   - S3 버킷: penguin-land-shared-tfstate (1개만)
#   - DynamoDB 테이블: penguin-land-shared-tflock (1개만)
# 
# 사용법:
#   ./scripts/bootstrap-backend.sh
# 
# 주의:
#   - 이 스크립트는 최초 1회만 실행하세요
#   - 이미 버킷이 존재하면 건너뜁니다
# ===================================================================

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 설정
REGION="${AWS_REGION:-ap-northeast-2}"  # 한국-서울 리전
BUCKET_NAME="${TFSTATE_BUCKET:-penguin-land-shared-tfstate}"
LOCK_TABLE="${LOCK_TABLE:-penguin-land-shared-tflock}"

echo -e "${GREEN}=== Terraform Backend Bootstrap ===${NC}"
echo "Region: $REGION"
echo "S3 Bucket: $BUCKET_NAME"
echo "DynamoDB Table: $LOCK_TABLE"
echo ""

# 1. S3 버킷 생성
echo -e "${YELLOW}[1/4] Creating S3 bucket...${NC}"
if aws s3 ls "s3://$BUCKET_NAME" 2>/dev/null; then
    echo -e "${GREEN}✓ Bucket already exists${NC}"
else
    aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$REGION" \
        --create-bucket-configuration LocationConstraint="$REGION"
    
    echo -e "${GREEN}✓ Bucket created${NC}"
fi

# 2. 버킷 버저닝 활성화
echo -e "${YELLOW}[2/4] Enabling bucket versioning...${NC}"
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

echo -e "${GREEN}✓ Versioning enabled${NC}"

# 3. 버킷 암호화 설정
echo -e "${YELLOW}[3/4] Configuring bucket encryption...${NC}"
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }]
    }'

echo -e "${GREEN}✓ Encryption configured${NC}"

# 4. DynamoDB 테이블 생성
echo -e "${YELLOW}[4/4] Creating DynamoDB lock table...${NC}"
if aws dynamodb describe-table --table-name "$LOCK_TABLE" --region "$REGION" 2>/dev/null; then
    echo -e "${GREEN}✓ Table already exists${NC}"
else
    aws dynamodb create-table \
        --table-name "$LOCK_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$REGION"
    
    echo -e "${GREEN}✓ Table created${NC}"
    
    echo "Waiting for table to be active..."
    aws dynamodb wait table-exists --table-name "$LOCK_TABLE" --region "$REGION"
fi

echo ""
echo -e "${GREEN}=== Bootstrap Complete ===${NC}"
echo ""
echo -e "${BLUE}생성된 리소스:${NC}"
echo "  ✅ S3 버킷: $BUCKET_NAME"
echo "  ✅ DynamoDB 테이블: $LOCK_TABLE"
echo ""
echo -e "${YELLOW}다음 단계:${NC}"
echo "1. backend.tf 파일이 이미 설정되어 있습니다 (확인만 하세요)"
echo "2. Terraform 초기화: terraform init"
echo "3. Workspace 생성: terraform workspace new user-001"
echo "4. 인프라 배포: terraform apply"
echo ""
echo -e "${BLUE}State 저장 위치:${NC}"
echo "  s3://$BUCKET_NAME/env:/user-001/terraform.tfstate"
echo "  s3://$BUCKET_NAME/env:/user-002/terraform.tfstate"
echo ""
echo -e "${GREEN}Backend 설정이 완료되었습니다! 🎉${NC}"
