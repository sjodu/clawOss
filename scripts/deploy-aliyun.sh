#!/bin/bash
# ClawOSS 阿里云一键部署脚本
# 适用于：Alibaba Cloud Linux 3 + 1核2GB + Docker

set -e

echo "=========================================="
echo "  ClawOSS 阿里云一键部署脚本"
echo "  系统要求：Alibaba Cloud Linux 3"
echo "  配置要求：1核2GB 或更高"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否为 root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}错误：请使用 root 用户运行此脚本${NC}"
  echo "使用方法：sudo bash $0"
  exit 1
fi

# 步骤 1：安装 Docker
echo -e "${GREEN}[1/7] 安装 Docker...${NC}"
if ! command -v docker &> /dev/null; then
    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    echo -e "${GREEN}✓ Docker 安装完成${NC}"
else
    echo -e "${YELLOW}✓ Docker 已安装，跳过${NC}"
fi

# 步骤 2：安装 Docker Compose
echo -e "${GREEN}[2/7] 安装 Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}✓ Docker Compose 安装完成${NC}"
else
    echo -e "${YELLOW}✓ Docker Compose 已安装，跳过${NC}"
fi

# 步骤 3：安装 Git
echo -e "${GREEN}[3/7] 安装 Git...${NC}"
if ! command -v git &> /dev/null; then
    yum install -y git
    echo -e "${GREEN}✓ Git 安装完成${NC}"
else
    echo -e "${YELLOW}✓ Git 已安装，跳过${NC}"
fi

# 步骤 4：克隆项目
echo -e "${GREEN}[4/7] 克隆 ClawOSS 项目...${NC}"
INSTALL_DIR="/opt/clawOss"
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}目录已存在，是否删除并重新克隆？(y/n)${NC}"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        rm -rf "$INSTALL_DIR"
        git clone https://github.com/sjodu/clawOss.git "$INSTALL_DIR"
        echo -e "${GREEN}✓ 项目克隆完成${NC}"
    else
        echo -e "${YELLOW}✓ 使用现有项目目录${NC}"
    fi
else
    git clone https://github.com/sjodu/clawOss.git "$INSTALL_DIR"
    echo -e "${GREEN}✓ 项目克隆完成${NC}"
fi

cd "$INSTALL_DIR"

# 步骤 5：配置环境变量
echo -e "${GREEN}[5/7] 配置环境变量...${NC}"
if [ ! -f .env ]; then
    echo -e "${YELLOW}请输入配置信息：${NC}"

    # LLM 配置
    read -p "LLM Provider (默认: deepseek): " LLM_PROVIDER
    LLM_PROVIDER=${LLM_PROVIDER:-deepseek}

    read -p "LLM Model (默认: deepseek-chat): " LLM_MODEL
    LLM_MODEL=${LLM_MODEL:-deepseek-chat}

    read -p "LLM API Key: " LLM_API_KEY

    read -p "LLM Base URL (默认: https://api.deepseek.com): " LLM_BASE_URL
    LLM_BASE_URL=${LLM_BASE_URL:-https://api.deepseek.com}

    read -p "输入 Token 成本 ($/M, 默认: 0.14): " LLM_COST_INPUT
    LLM_COST_INPUT=${LLM_COST_INPUT:-0.14}

    read -p "输出 Token 成本 ($/M, 默认: 0.28): " LLM_COST_OUTPUT
    LLM_COST_OUTPUT=${LLM_COST_OUTPUT:-0.28}

    # 预算配置
    read -p "预算上限 (USD, 默认: 5.0): " BUDGET_MAX_USD
    BUDGET_MAX_USD=${BUDGET_MAX_USD:-5.0}

    # GitHub 配置
    read -p "GitHub Token: " GH_TOKEN
    read -p "GitHub Username: " GH_USERNAME
    read -p "GitHub Email: " GH_EMAIL

    # 创建 .env 文件
    cat > .env << EOF
# ===== LLM 配置 =====
LLM_PROVIDER=${LLM_PROVIDER}
LLM_MODEL=${LLM_MODEL}
LLM_API_KEY=${LLM_API_KEY}
LLM_BASE_URL=${LLM_BASE_URL}
LLM_COST_INPUT=${LLM_COST_INPUT}
LLM_COST_OUTPUT=${LLM_COST_OUTPUT}

# ===== 预算控制 =====
BUDGET_MAX_USD=${BUDGET_MAX_USD}

# ===== GitHub 配置 =====
GH_TOKEN=${GH_TOKEN}
GH_USERNAME=${GH_USERNAME}
GH_EMAIL=${GH_EMAIL}

# ===== OpenClaw 版本 =====
OPENCLAW_VERSION=latest
EOF
    echo -e "${GREEN}✓ 环境变量配置完成${NC}"
else
    echo -e "${YELLOW}✓ .env 文件已存在，跳过配置${NC}"
fi

# 步骤 6：创建 Swap（1核2GB 需要）
echo -e "${GREEN}[6/7] 配置 Swap 空间...${NC}"
if [ ! -f /swapfile ]; then
    echo -e "${YELLOW}创建 2GB Swap 空间（防止内存不足）...${NC}"
    dd if=/dev/zero of=/swapfile bs=1M count=2048
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    echo -e "${GREEN}✓ Swap 配置完成${NC}"
else
    echo -e "${YELLOW}✓ Swap 已存在，跳过${NC}"
fi

# 步骤 7：启动服务
echo -e "${GREEN}[7/7] 启动 ClawOSS 服务...${NC}"
docker-compose up -d

echo ""
echo -e "${GREEN}=========================================="
echo "  部署完成！"
echo "==========================================${NC}"
echo ""
echo -e "${YELLOW}下一步操作：${NC}"
echo ""
echo "1. 配置防火墙（开放 18789 端口）："
echo "   firewall-cmd --permanent --add-port=18789/tcp"
echo "   firewall-cmd --reload"
echo ""
echo "2. 配置阿里云安全组："
echo "   登录阿里云控制台 → ECS → 安全组 → 添加规则"
echo "   端口：18789，协议：TCP，授权对象：0.0.0.0/0"
echo ""
echo "3. 获取 Gateway Token："
echo "   docker-compose exec clawoss cat /root/.openclaw/gateway-token.txt"
echo ""
echo "4. 访问 Dashboard："
SERVER_IP=$(curl -s ifconfig.me)
echo "   http://${SERVER_IP}:18789"
echo ""
echo "5. 查看日志："
echo "   docker-compose logs -f"
echo ""
echo -e "${GREEN}常用命令：${NC}"
echo "  启动服务：docker-compose up -d"
echo "  停止服务：docker-compose down"
echo "  查看状态：docker-compose ps"
echo "  查看日志：docker-compose logs -f"
echo ""
echo -e "${YELLOW}提示：首次启动需要 2-3 分钟初始化，请耐心等待${NC}"
echo ""
