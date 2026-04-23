# ClawOSS Docker 部署指南

## 快速开始

### 1. 准备环境变量

复制示例配置文件：
```bash
cp .env.example .env
```

编辑 `.env` 文件，填入必需的配置：
```bash
# 必需配置
LLM_API_KEY=your-api-key-here
GITHUB_TOKEN=your-github-token-here

# 可选配置（已有默认值）
LLM_PROVIDER=deepseek
LLM_MODEL=deepseek-chat
BUDGET_MAX_USD=5.0
GITHUB_USERNAME=your-username
GITHUB_EMAIL=your-email@example.com
```

### 2. 构建并启动

```bash
# 构建镜像
docker-compose build

# 启动容器
docker-compose up -d

# 查看日志
docker-compose logs -f
```

### 3. 验证运行

```bash
# 检查容器状态
docker-compose ps

# 查看预算状态
docker-compose exec clawoss cat workspace/memory/budget-spent.txt
docker-compose exec clawoss cat workspace/memory/budget-max.txt

# 查看 OpenClaw 状态
docker-compose exec clawoss openclaw gateway status
```

## 管理命令

### 启动/停止

```bash
# 启动
docker-compose up -d

# 停止
docker-compose down

# 重启
docker-compose restart

# 停止并删除数据卷
docker-compose down -v
```

### 查看日志

```bash
# 实时日志
docker-compose logs -f

# 最近 100 行
docker-compose logs --tail=100

# 特定时间范围
docker-compose logs --since 1h
```

### 进入容器

```bash
# 进入容器 shell
docker-compose exec clawoss bash

# 执行单个命令
docker-compose exec clawoss openclaw gateway status
```

### 预算管理

```bash
# 查看预算状态
docker-compose exec clawoss bash scripts/budget-status.sh

# 重置预算
docker-compose exec clawoss bash scripts/budget-reset.sh
```

## 配置说明

### 环境变量

| 变量 | 必需 | 默认值 | 说明 |
|------|------|--------|------|
| `LLM_API_KEY` | ✅ | - | LLM API 密钥 |
| `GITHUB_TOKEN` | ✅ | - | GitHub Personal Access Token |
| `LLM_PROVIDER` | ❌ | `deepseek` | LLM 提供商 |
| `LLM_MODEL` | ❌ | `deepseek-chat` | 模型名称 |
| `LLM_BASE_URL` | ❌ | `https://api.deepseek.com` | API 端点 |
| `LLM_COST_INPUT` | ❌ | `0.14` | 输入成本（$/M tokens）|
| `LLM_COST_OUTPUT` | ❌ | `0.28` | 输出成本（$/M tokens）|
| `BUDGET_MAX_USD` | ❌ | `5.0` | 预算上限（美元）|
| `GITHUB_USERNAME` | ❌ | `sjodu` | Git 用户名 |
| `GITHUB_EMAIL` | ❌ | `1149095175@qq.com` | Git 邮箱 |

### 数据持久化

容器使用以下卷保存数据：

- `openclaw-data`: OpenClaw 配置和缓存
- `./workspace/memory`: 预算、仓库、问题数据
- `./logs`: 运行日志

### 资源限制

默认配置：
- CPU: 1-2 核
- 内存: 2-4 GB

可在 `docker-compose.yml` 中调整：
```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 4G
```

## 支持的 LLM 提供商

### DeepSeek（推荐，成本最低）
```bash
LLM_PROVIDER=deepseek
LLM_MODEL=deepseek-chat
LLM_BASE_URL=https://api.deepseek.com
LLM_COST_INPUT=0.14
LLM_COST_OUTPUT=0.28
```

### OpenAI
```bash
LLM_PROVIDER=openai
LLM_MODEL=gpt-4o-mini
LLM_BASE_URL=https://api.openai.com/v1
LLM_COST_INPUT=0.15
LLM_COST_OUTPUT=0.6
```

### Anthropic
```bash
LLM_PROVIDER=anthropic
LLM_MODEL=claude-3-5-sonnet-20241022
LLM_BASE_URL=https://api.anthropic.com
LLM_COST_INPUT=3.0
LLM_COST_OUTPUT=15.0
```

### OpenRouter
```bash
LLM_PROVIDER=openrouter
LLM_MODEL=anthropic/claude-3.5-sonnet
LLM_BASE_URL=https://openrouter.ai/api/v1
```

## 故障排查

### 容器无法启动

1. 检查环境变量：
```bash
docker-compose config
```

2. 查看构建日志：
```bash
docker-compose build --no-cache
```

3. 查看容器日志：
```bash
docker-compose logs
```

### OpenClaw 认证失败

```bash
# 重新认证
docker-compose exec clawoss bash -c 'echo "$GITHUB_TOKEN" | gh auth login --with-token'

# 验证认证
docker-compose exec clawoss gh auth status
```

### 预算达到上限

```bash
# 查看当前预算
docker-compose exec clawoss bash scripts/budget-status.sh

# 重置预算（谨慎操作）
docker-compose exec clawoss bash scripts/budget-reset.sh

# 或修改 .env 中的 BUDGET_MAX_USD 并重启
docker-compose restart
```

### 内存不足

增加内存限制：
```yaml
# docker-compose.yml
deploy:
  resources:
    limits:
      memory: 8G
```

### 网络问题

检查 API 连接：
```bash
docker-compose exec clawoss curl -I https://api.deepseek.com
docker-compose exec clawoss curl -I https://api.github.com
```

## 生产部署建议

### 1. 使用外部配置管理

不要在 `.env` 文件中存储敏感信息，使用：
- Docker Secrets
- Kubernetes Secrets
- AWS Secrets Manager
- HashiCorp Vault

### 2. 配置日志收集

```yaml
logging:
  driver: "syslog"
  options:
    syslog-address: "tcp://logs.example.com:514"
```

### 3. 设置监控告警

监控指标：
- 容器健康状态
- 预算使用情况
- API 调用失败率
- 内存/CPU 使用率

### 4. 定期备份

```bash
# 备份数据卷
docker run --rm -v clawoss_openclaw-data:/data -v $(pwd):/backup \
  alpine tar czf /backup/openclaw-backup-$(date +%Y%m%d).tar.gz /data

# 备份 memory 目录
tar czf memory-backup-$(date +%Y%m%d).tar.gz workspace/memory
```

### 5. 使用编排工具

对于生产环境，建议使用：
- Kubernetes (推荐)
- Docker Swarm
- AWS ECS
- Google Cloud Run

## 性能优化

### 1. 调整并发数

编辑 `workspace/HEARTBEAT.md`，修改步骤 1 中的并发数：
```bash
openclaw gateway start --max-concurrent 3
```

### 2. 使用本地缓存

挂载更多缓存目录：
```yaml
volumes:
  - ./cache:/app/cache
```

### 3. 网络优化

使用 CDN 或代理加速 API 访问：
```bash
LLM_BASE_URL=https://your-proxy.example.com/v1
```

## 安全建议

1. **最小权限原则**：GitHub Token 只授予必需的权限
2. **定期轮换密钥**：定期更换 API Key 和 Token
3. **网络隔离**：使用 Docker 网络隔离
4. **镜像扫描**：定期扫描镜像漏洞
5. **日志脱敏**：确保日志不包含敏感信息

## 更新升级

```bash
# 拉取最新代码
git pull

# 重新构建
docker-compose build --no-cache

# 重启服务
docker-compose up -d

# 验证版本
docker-compose exec clawoss openclaw --version
```

## 支持

- 问题反馈：GitHub Issues
- 文档：[README.md](README.md)
- 实施指南：[安装启动指南.md](安装启动指南.md)
