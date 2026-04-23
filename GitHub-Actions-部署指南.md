# GitHub Actions 部署指南

## 概述

使用 GitHub Actions 可以**完全免费**地运行 ClawOSS，无需购买服务器！

### 优势
- ✅ **完全免费**（GitHub Actions 每月 2000 分钟免费额度）
- ✅ **零运维**（GitHub 自动管理基础设施）
- ✅ **自动运行**（定时触发，无需人工干预）
- ✅ **版本控制**（所有配置和代码都在 Git 中）
- ✅ **日志完整**（每次运行都有详细日志）

### 限制
- ⚠️ 每次运行最长 6 小时
- ⚠️ 并发任务有限制
- ⚠️ 不适合需要持续运行的场景

---

## 部署步骤

### Step 1: 创建 GitHub 仓库

1. 登录 GitHub
2. 创建新仓库（例如：`ClawOSS-Runner`）
3. 设置为 **Private**（保护敏感信息）

### Step 2: 上传项目文件

```bash
# 在本地项目目录
cd /Users/jiangjiang/Downloads/ClawOSS-6-release

# 初始化 Git（如果还没有）
git init

# 添加远程仓库
git remote add origin https://github.com/your-username/ClawOSS-Runner.git

# 添加所有文件
git add .

# 提交
git commit -m "Initial commit: ClawOSS project"

# 推送到 GitHub
git push -u origin main
```

### Step 3: 配置 GitHub Secrets

在 GitHub 仓库中配置敏感信息：

1. 进入仓库 → **Settings** → **Secrets and variables** → **Actions**
2. 点击 **New repository secret**
3. 添加以下 secrets：

| Secret 名称 | 值 | 说明 |
|------------|-----|------|
| `LLM_PROVIDER` | `deepseek` | LLM 提供商 |
| `LLM_MODEL` | `deepseek-chat` | 模型名称 |
| `LLM_API_KEY` | `sk-9e9317850a414aababae91799a40a98d` | DeepSeek API Key |
| `LLM_BASE_URL` | `https://api.deepseek.com` | API 端点 |
| `LLM_COST_INPUT` | `0.14` | 输入成本（每百万 token） |
| `LLM_COST_OUTPUT` | `0.28` | 输出成本（每百万 token） |
| `BUDGET_MAX_USD` | `5.0` | 预算上限（美元） |
| `GH_TOKEN` | `ghp_your_github_token_here` | GitHub Token |
| `GH_USERNAME` | `sjodu` | GitHub 用户名 |
| `GH_EMAIL` | `1149095175@qq.com` | GitHub 邮箱 |

**注意：** 使用 `GH_TOKEN` 而不是 `GITHUB_TOKEN`，因为后者是 GitHub Actions 的保留变量。

### Step 4: 启用 GitHub Actions

1. 进入仓库 → **Actions** 标签
2. 如果看到提示，点击 **I understand my workflows, go ahead and enable them**
3. 找到 **ClawOSS Autonomous Runner** workflow
4. 点击 **Enable workflow**

### Step 5: 手动触发第一次运行

1. 在 **Actions** 标签中
2. 选择 **ClawOSS Autonomous Runner**
3. 点击 **Run workflow** → **Run workflow**
4. 等待运行完成（约 5-10 分钟）

### Step 6: 查看运行结果

1. 点击运行记录查看详细日志
2. 查看 **Summary** 了解 PR 提交情况
3. 下载 **Artifacts** 查看完整日志

---

## 运行模式

### 1. 定时运行（推荐）

当前配置：**每小时运行一次**（已优化）

```yaml
schedule:
  - cron: '0 * * * *'  # 每小时整点运行
```

**其他选项：**
```yaml
# 每 2 小时
- cron: '0 */2 * * *'

# 每 4 小时
- cron: '0 */4 * * *'

# 每天早上 9 点
- cron: '0 9 * * *'

# 工作日每小时（9am-6pm）
- cron: '0 9-18 * * 1-5'
```

### 2. 手动触发

在 Actions 页面点击 **Run workflow** 按钮

### 3. Push 触发

每次推送代码到 `main` 分支时自动运行

---

## 预算控制

### 自动预算追踪

Workflow 会自动：
1. 检查当前预算使用情况
2. 如果超出预算，停止运行
3. 将预算数据提交回仓库

### 查看预算

在 Actions 运行日志中查看：
```
Budget spent: $0.50 / $5.0
✅ Budget OK. Remaining: $4.50
```

### 重置预算

如果需要重置预算：

```bash
# 本地修改
echo "0.0" > workspace/memory/budget-spent.txt

# 提交并推送
git add workspace/memory/budget-spent.txt
git commit -m "chore: reset budget"
git push
```

---

## GitHub Actions 免费额度

### 免费计划
- **2000 分钟/月**（公共仓库无限）
- **500 MB 存储**
- **20 个并发任务**

### 使用量估算

**当前配置（每小时运行一次）：**
- 时长：8-10 分钟/次
- 频率：每小时一次
- 每天运行次数：24 次
- 每天消耗：192-240 分钟
- **每月消耗：约 5760-7200 分钟**

**⚠️ 注意：** 免费额度 2000 分钟/月，每小时运行会在 **8-10 天**用完！

**推荐配置（每 2 小时）：**
```yaml
schedule:
  - cron: '0 */2 * * *'  # 每 2 小时

# 每天消耗：12 × 10 = 120 分钟
# 可运行天数：2000 / 120 ≈ 16 天
```

**最优配置（每 4 小时）：**
```yaml
schedule:
  - cron: '0 */4 * * *'  # 每 4 小时

# 每天消耗：6 × 10 = 60 分钟
# 可运行天数：2000 / 60 ≈ 33 天（整月）
```

---

## 优化建议

### 1. 调整运行频率（重要）

当前配置：**每小时运行**，会在 8-10 天用完免费额度。

**推荐修改为每 4 小时：**

编辑 `.github/workflows/clawoss-runner.yml`：

```yaml
schedule:
  # 每 4 小时运行一次（推荐）
  - cron: '0 */4 * * *'
  
  # 或每 2 小时（如果需要更频繁）
  # - cron: '0 */2 * * *'
```

### 2. 使用 GitHub Actions 缓存（已启用）

已添加缓存优化，加速后续运行：

```yaml
- name: Cache OpenClaw
  uses: actions/cache@v4
  with:
    path: |
      ~/.openclaw
      ~/.npm
    key: ${{ runner.os }}-openclaw-${{ hashFiles('**/package-lock.json') }}
```

### 3. 并行运行多个任务

创建多个 workflow 文件：
- `clawoss-discover.yml` - 发现 issues
- `clawoss-implement.yml` - 实现修复
- `clawoss-followup.yml` - 跟进 PR

### 4. 使用 Self-hosted Runner

如果有自己的服务器，可以配置 self-hosted runner：
- 无时间限制
- 无并发限制
- 完全免费

---

## 监控和调试

### 查看运行日志

1. 进入 **Actions** 标签
2. 点击运行记录
3. 展开各个步骤查看详细日志

### 下载日志文件

1. 在运行记录页面
2. 滚动到底部 **Artifacts**
3. 下载 `clawoss-logs-xxx.zip`

### 查看 PR 统计

在运行 Summary 中查看：
```json
{
  "number": 13324,
  "title": "fix(image): preserve resolution",
  "state": "OPEN"
}
```

### 调试失败的运行

如果运行失败：

1. 查看错误日志
2. 检查 Secrets 配置是否正确
3. 验证 API Key 是否有效
4. 检查预算是否耗尽

---

## 高级配置

### 1. 多账号运行

创建多个 workflow，使用不同的 GitHub 账号：

```yaml
# .github/workflows/clawoss-account1.yml
env:
  GH_USERNAME: account1
  GH_TOKEN: ${{ secrets.GH_TOKEN_ACCOUNT1 }}

# .github/workflows/clawoss-account2.yml
env:
  GH_USERNAME: account2
  GH_TOKEN: ${{ secrets.GH_TOKEN_ACCOUNT2 }}
```

### 2. 条件运行

只在特定条件下运行：

```yaml
- name: Run ClawOSS
  if: github.event_name == 'schedule' || github.event_name == 'workflow_dispatch'
  run: |
    bash scripts/restart.sh
```

### 3. 通知集成

运行完成后发送通知：

```yaml
- name: Send notification
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

---

## 与 VPS 部署对比

| 特性 | GitHub Actions | VPS |
|------|---------------|-----|
| 成本 | 免费（有限额） | $20-30/月 |
| 运行时长 | 最长 6 小时 | 无限制 |
| 运行频率 | 受限于免费额度 | 无限制 |
| 维护成本 | 零 | 需要维护 |
| 灵活性 | 中等 | 高 |
| 适用场景 | 测试、小规模 | 生产、大规模 |

---

## 推荐方案

### 方案 A：纯 GitHub Actions（免费）
- 每 2 小时运行一次
- 每月约 360 次运行
- 适合：测试、学习、小规模使用

### 方案 B：混合方案（最优）
- GitHub Actions：发现 issues（每小时）
- VPS：实现和跟进（持续运行）
- 成本：$20/月
- 适合：生产环境

### 方案 C：Self-hosted Runner（推荐）
- 在自己的服务器上运行 GitHub Actions
- 无时间和频率限制
- 保留 GitHub Actions 的便利性
- 适合：有服务器资源的用户

---

## 快速开始

```bash
# 1. Fork 或创建仓库
# 2. 配置 Secrets（10 个）
# 3. 启用 Actions
# 4. 手动触发第一次运行
# 5. 查看日志和 PR

# 完成！系统将自动运行
```

---

## 故障排查

### 问题 1：Workflow 不运行

**原因：** 仓库可能禁用了 Actions

**解决：**
1. Settings → Actions → General
2. 选择 "Allow all actions and reusable workflows"

### 问题 2：预算检查失败

**原因：** 预算文件不存在或格式错误

**解决：**
```bash
echo "0.0" > workspace/memory/budget-spent.txt
echo "5.0" > workspace/memory/budget-max.txt
git add workspace/memory/*.txt
git commit -m "fix: initialize budget files"
git push
```

### 问题 3：GitHub 认证失败

**原因：** Token 权限不足

**解决：**
1. 重新生成 GitHub Token
2. 确保包含 `repo` 和 `workflow` 权限
3. 更新 `GH_TOKEN` Secret

### 问题 4：超出免费额度

**原因：** 运行频率太高

**解决：**
1. 降低运行频率（改为每 2-4 小时）
2. 或升级到 GitHub Pro（$4/月，3000 分钟）
3. 或使用 self-hosted runner

---

## 总结

GitHub Actions 是一个**零成本**的 ClawOSS 部署方案，适合：
- ✅ 测试和学习
- ✅ 小规模使用
- ✅ 预算有限的个人用户

如果需要大规模生产环境，建议使用 VPS 或混合方案。
