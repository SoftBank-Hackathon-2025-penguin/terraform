# Data source for latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# User data script for EC2 initialization
locals {
  user_data = <<-EOF
    #!/bin/bash
    set -e
    
    # Update system
    yum update -y
    
    # Install Java 17 for Spring Boot
    amazon-linux-extras install java-openjdk11 -y
    yum install java-17-amazon-corretto-headless -y
    
    # Install Terraform
    yum install -y yum-utils
    yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
    yum install terraform -y
    
    # Install Docker (optional, for containerized apps)
    yum install docker -y
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user
    
    # Install CloudWatch agent
    wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
    rpm -U ./amazon-cloudwatch-agent.rpm
    
    # Create application directory
    mkdir -p /opt/penguin-land
    chown ec2-user:ec2-user /opt/penguin-land
    
    # Configure CloudWatch agent
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWCONFIG'
    {
      "metrics": {
        "namespace": "PenguinLand/${var.session_id}",
        "metrics_collected": {
          "cpu": {
            "measurement": [
              {
                "name": "cpu_usage_idle",
                "rename": "CPU_IDLE",
                "unit": "Percent"
              },
              {
                "name": "cpu_usage_iowait",
                "rename": "CPU_IOWAIT",
                "unit": "Percent"
              }
            ],
            "metrics_collection_interval": 60,
            "totalcpu": false
          },
          "disk": {
            "measurement": [
              {
                "name": "used_percent",
                "rename": "DISK_USED",
                "unit": "Percent"
              }
            ],
            "metrics_collection_interval": 60,
            "resources": [
              "*"
            ]
          },
          "mem": {
            "measurement": [
              {
                "name": "mem_used_percent",
                "rename": "MEM_USED",
                "unit": "Percent"
              }
            ],
            "metrics_collection_interval": 60
          }
        }
      },
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/opt/penguin-land/logs/application.log",
                "log_group_name": "/aws/ec2/penguin-land/${var.session_id}",
                "log_stream_name": "{instance_id}/application"
              }
            ]
          }
        }
      }
    }
    CWCONFIG
    
    # Start CloudWatch agent
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config \
      -m ec2 \
      -s \
      -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
    
    # Set environment variables
    echo "export SESSION_ID=${var.session_id}" >> /home/ec2-user/.bashrc
    echo "export PROJECT_NAME=${var.project_name}" >> /home/ec2-user/.bashrc
    
    # Signal completion
    echo "EC2 initialization completed at $(date)" > /tmp/init-complete.txt
  EOF
}

# EC2 Instance
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = var.ec2_key_name != "" ? var.ec2_key_name : null

  user_data = local.user_data

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "${var.project_name}-${var.session_id}-root-volume"
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  monitoring = true

  tags = {
    Name        = "${var.project_name}-${var.session_id}-app-server"
    Application = "Spring Boot"
    Role        = "Application Server"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP for EC2 (선택적, 고정 IP가 필요한 경우)
resource "aws_eip" "app_server" {
  instance = aws_instance.app_server.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-${var.session_id}-eip"
  }

  depends_on = [aws_internet_gateway.main]
}
