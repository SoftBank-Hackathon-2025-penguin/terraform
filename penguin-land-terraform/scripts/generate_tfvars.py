# Workspace별 변수 템플릿 생성기
# 사용법: python3 generate_tfvars.py --user-id user-001 --email test@example.com

import argparse
import json
from pathlib import Path

TEMPLATE = """# Auto-generated tfvars for {user_id}
# Generated at: {timestamp}

# === 필수 설정 ===
session_id      = "{user_id}"
project_name    = "penguin-land"
aws_region      = "{region}"

# === EC2 설정 ===
ec2_instance_type = "{instance_type}"
{ec2_key_line}

# === 알림 설정 ===
{alert_email_line}

# === 모니터링 임계값 ===
cpu_warning_threshold  = {cpu_warning}
cpu_critical_threshold = {cpu_critical}

error_rate_warning_threshold  = {error_warning}
error_rate_critical_threshold = {error_critical}

latency_warning_threshold  = {latency_warning}
latency_critical_threshold = {latency_critical}

# === 환경 설정 ===
environment = "{environment}"

# === 커스텀 태그 ===
common_tags = {{
  Project     = "penguin-land"
  ManagedBy   = "terraform"
  UserId      = "{user_id}"
  Environment = "{environment}"
}}
"""

def generate_tfvars(args):
    """tfvars 파일 생성"""
    from datetime import datetime
    
    # EC2 키 페어 설정
    ec2_key_line = f'ec2_key_name    = "{args.ec2_key}"' if args.ec2_key else '# ec2_key_name    = ""  # SSH 키페어 (선택적)'
    
    # 이메일 설정
    alert_email_line = f'alert_email     = "{args.email}"' if args.email else '# alert_email     = ""  # 알람 이메일 (선택적)'
    
    content = TEMPLATE.format(
        user_id=args.user_id,
        timestamp=datetime.now().isoformat(),
        region=args.region,
        instance_type=args.instance_type,
        ec2_key_line=ec2_key_line,
        alert_email_line=alert_email_line,
        cpu_warning=args.cpu_warning,
        cpu_critical=args.cpu_critical,
        error_warning=args.error_warning,
        error_critical=args.error_critical,
        latency_warning=args.latency_warning,
        latency_critical=args.latency_critical,
        environment=args.environment
    )
    
    # 파일 저장
    output_file = Path(f"{args.user_id}.auto.tfvars")
    output_file.write_text(content)
    
    print(f"✓ Generated: {output_file}")
    print(f"\nNext steps:")
    print(f"1. Review the generated file: {output_file}")
    print(f"2. Create workspace: terraform workspace new {args.user_id}")
    print(f"3. Deploy: terraform apply -var-file={output_file}")

def main():
    parser = argparse.ArgumentParser(
        description="Generate Terraform tfvars file for a user workspace"
    )
    
    # 필수 인자
    parser.add_argument(
        '--user-id',
        required=True,
        help='Unique user ID (e.g., user-001, company-dev-01)'
    )
    
    # 선택적 인자
    parser.add_argument(
        '--region',
        default='ap-northeast-1',
        choices=['ap-northeast-1', 'us-east-1', 'us-west-2', 'eu-west-1'],
        help='AWS region (default: ap-northeast-1)'
    )
    
    parser.add_argument(
        '--instance-type',
        default='t2.micro',
        choices=['t2.micro', 't2.small', 't2.medium', 't3.micro', 't3.small'],
        help='EC2 instance type (default: t2.micro)'
    )
    
    parser.add_argument(
        '--ec2-key',
        default=None,
        help='EC2 SSH key pair name (optional)'
    )
    
    parser.add_argument(
        '--email',
        default=None,
        help='Email address for alerts (optional)'
    )
    
    parser.add_argument(
        '--cpu-warning',
        type=int,
        default=50,
        help='CPU warning threshold in percent (default: 50)'
    )
    
    parser.add_argument(
        '--cpu-critical',
        type=int,
        default=70,
        help='CPU critical threshold in percent (default: 70)'
    )
    
    parser.add_argument(
        '--error-warning',
        type=int,
        default=3,
        help='Error rate warning threshold in percent (default: 3)'
    )
    
    parser.add_argument(
        '--error-critical',
        type=int,
        default=5,
        help='Error rate critical threshold in percent (default: 5)'
    )
    
    parser.add_argument(
        '--latency-warning',
        type=int,
        default=400,
        help='Latency warning threshold in ms (default: 400)'
    )
    
    parser.add_argument(
        '--latency-critical',
        type=int,
        default=700,
        help='Latency critical threshold in ms (default: 700)'
    )
    
    parser.add_argument(
        '--environment',
        default='dev',
        choices=['dev', 'staging', 'prod'],
        help='Environment type (default: dev)'
    )
    
    args = parser.parse_args()
    
    # 검증
    if args.cpu_warning >= args.cpu_critical:
        parser.error("CPU warning threshold must be less than critical threshold")
    
    if args.error_warning >= args.error_critical:
        parser.error("Error warning threshold must be less than critical threshold")
    
    if args.latency_warning >= args.latency_critical:
        parser.error("Latency warning threshold must be less than critical threshold")
    
    generate_tfvars(args)

if __name__ == '__main__':
    main()
