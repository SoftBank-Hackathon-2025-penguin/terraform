# modules/rds/main.tf

# [개선 1] RDS Enhanced Monitoring을 위한 IAM 역할 추가
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.project_name}-${var.environment}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "monitoring.rds.amazonaws.com" }
    }]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-monitoring-role"
  }
}

# RDS Enhanced Monitoring 정책 연결
resource "aws_iam_role_policy_attachment" "rds_monitoring_attach" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# DB 서브넷 그룹
resource "aws_db_subnet_group" "main" {
  count = var.vpc_id != null ? 1 : 0

  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  }
}

# 보안 그룹
resource "aws_security_group" "rds" {
  count = var.vpc_id != null ? 1 : 0

  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Security group for RDS"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.engine == "postgres" ? 5432 : 3306
    to_port     = var.engine == "postgres" ? 5432 : 3306
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected[0].cidr_block]
    description = "Database access from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  }
}

# VPC 데이터 조회
data "aws_vpc" "selected" {
  count = var.vpc_id != null ? 1 : 0
  id    = var.vpc_id
}

# RDS 인스턴스
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${var.environment}-db"

  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  allocated_storage    = var.allocated_storage
  storage_type         = "gp3"
  storage_encrypted    = true

  db_name  = var.db_name
  username = var.username
  password = var.password

  multi_az               = var.multi_az
  db_subnet_group_name   = var.vpc_id != null ? aws_db_subnet_group.main[0].name : null
  vpc_security_group_ids = var.vpc_id != null ? [aws_security_group.rds[0].id] : []

  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-${var.environment}-final-snapshot-${formatdate("YYYYMMDDhhmmss", timestamp())}"

  # [개선 1] Enhanced Monitoring 활성화 (60초 간격)
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  enabled_cloudwatch_logs_exports = var.engine == "postgres" ? ["postgresql"] : ["error", "general", "slowquery"]

  tags = {
    Name = "${var.project_name}-${var.environment}-rds"
  }
}
