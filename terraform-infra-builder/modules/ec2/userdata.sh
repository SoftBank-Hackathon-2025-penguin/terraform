#!/bin/bash
set -e

# 1. 기본 로그 설정
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "--- Server Initialization Start ---"

# 2. 시스템 업데이트 및 도구 설치
yum update -y
yum install -y amazon-cloudwatch-agent curl unzip

# 3. CloudWatch Agent 설정 (SSM 없이 로컬 설정 방식 - 복잡도 낮춤)
# 메모리, 디스크 사용량 모니터링 설정 생성
cat <<EOF > /opt/aws/amazon-cloudwatch-agent/bin/config.json
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "metrics": {
    "metrics_collected": {
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["used_percent"],
        "resources": ["*"],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

# 4. CloudWatch Agent 시작 (IAM Role이 CloudWatch 권한이 있어야 함 - 이미 되어있음)
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json

echo "--- Server Initialization Complete ---"