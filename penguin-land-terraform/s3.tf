# S3 Bucket for Static Files
resource "aws_s3_bucket" "static_files" {
  bucket = "${var.project_name}-${var.session_id}-static-files"

  tags = {
    Name    = "${var.project_name}-${var.session_id}-static-files"
    Purpose = "Static file storage"
  }
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "static_files" {
  bucket = aws_s3_bucket.static_files.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "static_files" {
  bucket = aws_s3_bucket.static_files.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ===================================================================
# Terraform State 저장용 S3 버킷 (공유)
# ===================================================================
# backend.tf에서 사용하는 공유 S3 버킷입니다.
# 
# 이 버킷은 bootstrap-backend.sh 스크립트로 생성됩니다.
# Terraform 코드로 관리하지 않으며, 수동으로 생성됩니다.
# 
# 버킷명: penguin-land-shared-tfstate
# 용도: 모든 workspace의 State 파일 저장
# 
# State 저장 구조:
#   s3://penguin-land-shared-tfstate/
#   ├── env:/user-001/terraform.tfstate
#   ├── env:/user-002/terraform.tfstate
#   └── env:/default/terraform.tfstate
# 
# 생성 방법:
#   ./scripts/bootstrap-backend.sh
# 
# 주의: 이 버킷은 Terraform으로 관리하지 않습니다.
#       수동으로 생성하고 수동으로 삭제해야 합니다.
# ===================================================================
