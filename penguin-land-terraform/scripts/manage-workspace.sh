#!/bin/bash
# Workspace 관리 유틸리티 스크립트

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 함수: 사용법 출력
usage() {
    echo "Usage: $0 {create|list|select|delete|status|deploy|destroy} [workspace-name]"
    echo ""
    echo "Commands:"
    echo "  create <name>   - Create a new workspace for a user"
    echo "  list            - List all workspaces"
    echo "  select <name>   - Switch to a specific workspace"
    echo "  delete <name>   - Delete a workspace (must destroy resources first)"
    echo "  status <name>   - Show deployment status for a workspace"
    echo "  deploy <name>   - Deploy infrastructure for a workspace"
    echo "  destroy <name>  - Destroy infrastructure for a workspace"
    echo ""
    echo "Examples:"
    echo "  $0 create user-001"
    echo "  $0 deploy user-001"
    echo "  $0 status user-001"
    echo "  $0 destroy user-001"
    exit 1
}

# 함수: Workspace 생성
create_workspace() {
    local workspace_name=$1
    
    if [ -z "$workspace_name" ]; then
        echo -e "${RED}Error: Workspace name required${NC}"
        usage
    fi
    
    echo -e "${YELLOW}Creating workspace: $workspace_name${NC}"
    
    if terraform workspace new "$workspace_name" 2>/dev/null; then
        echo -e "${GREEN}✓ Workspace created successfully${NC}"
        echo ""
        echo "Next steps:"
        echo "1. Create tfvars file: cp terraform.tfvars.example ${workspace_name}.auto.tfvars"
        echo "2. Edit the tfvars file with user-specific settings"
        echo "3. Deploy: $0 deploy $workspace_name"
    else
        echo -e "${YELLOW}⚠ Workspace already exists, selecting it...${NC}"
        terraform workspace select "$workspace_name"
    fi
}

# 함수: Workspace 목록
list_workspaces() {
    echo -e "${BLUE}=== Available Workspaces ===${NC}"
    terraform workspace list
    echo ""
    echo "Current workspace: $(terraform workspace show)"
}

# 함수: Workspace 선택
select_workspace() {
    local workspace_name=$1
    
    if [ -z "$workspace_name" ]; then
        echo -e "${RED}Error: Workspace name required${NC}"
        usage
    fi
    
    echo -e "${YELLOW}Selecting workspace: $workspace_name${NC}"
    terraform workspace select "$workspace_name"
    echo -e "${GREEN}✓ Switched to workspace: $workspace_name${NC}"
}

# 함수: Workspace 삭제
delete_workspace() {
    local workspace_name=$1
    
    if [ -z "$workspace_name" ]; then
        echo -e "${RED}Error: Workspace name required${NC}"
        usage
    fi
    
    if [ "$workspace_name" == "default" ]; then
        echo -e "${RED}Error: Cannot delete default workspace${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Deleting workspace: $workspace_name${NC}"
    echo -e "${RED}Warning: Make sure all resources are destroyed first!${NC}"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" == "yes" ]; then
        terraform workspace select default
        terraform workspace delete "$workspace_name"
        
        # tfvars 파일 삭제
        if [ -f "${workspace_name}.auto.tfvars" ]; then
            rm "${workspace_name}.auto.tfvars"
            echo -e "${GREEN}✓ Removed tfvars file${NC}"
        fi
        
        echo -e "${GREEN}✓ Workspace deleted${NC}"
    else
        echo "Cancelled"
    fi
}

# 함수: 배포 상태 확인
check_status() {
    local workspace_name=$1
    
    if [ -z "$workspace_name" ]; then
        workspace_name=$(terraform workspace show)
    fi
    
    echo -e "${BLUE}=== Workspace Status: $workspace_name ===${NC}"
    
    terraform workspace select "$workspace_name" 2>/dev/null || {
        echo -e "${RED}Error: Workspace not found${NC}"
        exit 1
    }
    
    echo ""
    echo -e "${YELLOW}Current Workspace:${NC}"
    terraform workspace show
    
    echo ""
    echo -e "${YELLOW}State Status:${NC}"
    terraform state list 2>/dev/null | head -20 || echo "No resources deployed"
    
    echo ""
    echo -e "${YELLOW}Resource Count:${NC}"
    terraform state list 2>/dev/null | wc -l || echo "0"
    
    echo ""
    echo -e "${YELLOW}Key Outputs:${NC}"
    terraform output -json 2>/dev/null | jq -r 'keys[]' | head -10 || echo "No outputs available"
}

# 함수: 인프라 배포
deploy_infrastructure() {
    local workspace_name=$1
    
    if [ -z "$workspace_name" ]; then
        echo -e "${RED}Error: Workspace name required${NC}"
        usage
    fi
    
    echo -e "${YELLOW}Deploying infrastructure for: $workspace_name${NC}"
    
    # Workspace 선택
    terraform workspace select "$workspace_name" 2>/dev/null || {
        echo -e "${YELLOW}Workspace not found, creating...${NC}"
        terraform workspace new "$workspace_name"
    }
    
    # tfvars 파일 확인
    if [ ! -f "${workspace_name}.auto.tfvars" ]; then
        echo -e "${RED}Error: ${workspace_name}.auto.tfvars not found${NC}"
        echo "Please create it from terraform.tfvars.example"
        exit 1
    fi
    
    echo ""
    echo -e "${YELLOW}[1/3] Initializing...${NC}"
    terraform init
    
    echo ""
    echo -e "${YELLOW}[2/3] Planning...${NC}"
    terraform plan -var-file="${workspace_name}.auto.tfvars" -out=tfplan
    
    echo ""
    echo -e "${YELLOW}[3/3] Applying...${NC}"
    read -p "Proceed with deployment? (yes/no): " confirm
    
    if [ "$confirm" == "yes" ]; then
        terraform apply tfplan
        rm tfplan
        
        echo ""
        echo -e "${GREEN}=== Deployment Complete ===${NC}"
        echo ""
        echo -e "${YELLOW}Resource Outputs:${NC}"
        terraform output
        
        echo ""
        echo -e "${YELLOW}Application URL:${NC}"
        terraform output -raw application_url 2>/dev/null || echo "Not available yet"
    else
        echo "Deployment cancelled"
        rm tfplan
    fi
}

# 함수: 인프라 삭제
destroy_infrastructure() {
    local workspace_name=$1
    
    if [ -z "$workspace_name" ]; then
        echo -e "${RED}Error: Workspace name required${NC}"
        usage
    fi
    
    if [ "$workspace_name" == "default" ]; then
        echo -e "${RED}Error: Cannot destroy default workspace${NC}"
        exit 1
    fi
    
    echo -e "${RED}=== Destroying Infrastructure ===${NC}"
    echo "Workspace: $workspace_name"
    echo ""
    echo -e "${RED}WARNING: This will destroy all AWS resources!${NC}"
    read -p "Type 'destroy-$workspace_name' to confirm: " confirm
    
    if [ "$confirm" == "destroy-$workspace_name" ]; then
        terraform workspace select "$workspace_name"
        
        if [ -f "${workspace_name}.auto.tfvars" ]; then
            terraform destroy -var-file="${workspace_name}.auto.tfvars" -auto-approve
        else
            terraform destroy -auto-approve
        fi
        
        echo -e "${GREEN}✓ Infrastructure destroyed${NC}"
        echo ""
        echo "To delete the workspace, run: $0 delete $workspace_name"
    else
        echo "Destruction cancelled"
    fi
}

# 메인 로직
case "$1" in
    create)
        create_workspace "$2"
        ;;
    list)
        list_workspaces
        ;;
    select)
        select_workspace "$2"
        ;;
    delete)
        delete_workspace "$2"
        ;;
    status)
        check_status "$2"
        ;;
    deploy)
        deploy_infrastructure "$2"
        ;;
    destroy)
        destroy_infrastructure "$2"
        ;;
    *)
        usage
        ;;
esac
