# GitHub Secrets 配置指南

## 访问 Secrets 配置页面

1. 打开仓库：https://github.com/sjodu/clawOss
2. 点击 **Settings** 标签
3. 左侧菜单选择 **Secrets and variables** → **Actions**
4. 点击 **New repository secret** 按钮

## 需要配置的 10 个 Secrets

按照以下顺序逐个添加：

### 1. LLM_PROVIDER
- **Name**: `LLM_PROVIDER`
- **Value**: `deepseek`

### 2. LLM_MODEL
- **Name**: `LLM_MODEL`
- **Value**: `deepseek-chat`

### 3. LLM_API_KEY
- **Name**: `LLM_API_KEY`
- **Value**: `sk-your_deepseek_api_key_here`
  - 替换为你的真实 DeepSeek API Key

### 4. LLM_BASE_URL
- **Name**: `LLM_BASE_URL`
- **Value**: `https://api.deepseek.com`

### 5. LLM_COST_INPUT
- **Name**: `LLM_COST_INPUT`
- **Value**: `0.14`

### 6. LLM_COST_OUTPUT
- **Name**: `LLM_COST_OUTPUT`
- **Value**: `0.28`

### 7. BUDGET_MAX
- **Name**: `BUDGET_MAX`
- **Value**: `5.0`

### 8. GH_USERNAME
- **Name**: `GH_USERNAME`
- **Value**: `sjodu`

### 9. GH_TOKEN
- **Name**: `GH_TOKEN`
- **Value**: `ghp_your_github_token_here`
  - 替换为你的真实 GitHub Personal Access Token
  - 需要权限：`repo`, `workflow`, `read:org`, `read:user`

### 10. OPENCLAW_VERSION
- **Name**: `OPENCLAW_VERSION`
- **Value**: `latest`

## 配置完成后

1. 进入 **Actions** 标签
2. 如果看到提示，点击 **I understand my workflows, go ahead and enable them**
3. 左侧选择 **ClawOSS Runner** workflow
4. 点击右上角 **Run workflow** 按钮
5. 选择 `main` 分支
6. 点击绿色的 **Run workflow** 按钮

## 监控运行状态

- 在 Actions 页面可以看到运行日志
- 每 4 小时自动运行一次
- 预算用完后会自动停止

## 注意事项

- GitHub Actions 免费版每月有 2000 分钟限制
- 每次运行约 10-30 分钟
- 建议监控前几次运行，确保配置正确
