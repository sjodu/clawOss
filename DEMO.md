# ClawOSS V11 验收演示文档

## 演示信息

- **项目版本**: ClawOSS V11
- **改造内容**: 灵活 LLM 配置 + 预算控制
- **演示日期**: 2026-04-23
- **服务器**: [填写你的服务器地址]
- **Dashboard**: [填写你的 Dashboard URL]
- **GitHub 账号**: [填写你的 GitHub 账号]

---

## 验收标准检查清单

### ✅ 1. 环境变量配置任意主流模型（无需改代码）

**演示命令**:
```bash
# 查看当前配置
cat .env | grep LLM_
```

**预期输出**:
```
LLM_PROVIDER=openai
LLM_MODEL=gpt-4o-mini
LLM_API_KEY=sk-xxx...
LLM_BASE_URL=https://api.openai.com/v1
LLM_COST_INPUT=0.15
LLM_COST_OUTPUT=0.6
```

**验证点**:
- ✅ 所有模型配置通过环境变量设置
- ✅ 无需修改任何代码文件
- ✅ 支持切换到其他模型（OpenAI, Anthropic, DeepSeek 等）

---

### ✅ 2. Token 总预算控制

**演示命令**:
```bash
# 查看预算状态
bash scripts/budget-status.sh
```

**预期输出**:
```
╔════════════════════════════════════════╗
║        BUDGET STATUS                   ║
╠════════════════════════════════════════╣
║ Max Budget:      $10.00                ║
║ Spent:           $2.35                 ║
║ Remaining:       $7.65                 ║
║ Usage:           23.50%                ║
╚════════════════════════════════════════╝

✅ Budget OK
```

**验证点**:
- ✅ 预算上限可配置（BUDGET_MAX_USD）
- ✅ 实时追踪已花费金额
- ✅ 达到上限时自动停止服务
- ✅ 可手动重置预算计数器

**预算超限测试**:
```bash
# 设置小预算测试熔断
echo "0.5" > workspace/memory/budget-max.txt

# 触发一次循环
openclaw system event --text "test cycle" --mode now

# 等待预算耗尽，系统应自动停止
# 检查日志
openclaw logs | grep -i budget
```

---

### ✅ 3. Dashboard 正常反映系统运行情况

**访问 Dashboard**: [你的 Dashboard URL]

**验证内容**:
- ✅ 实时心跳显示
- ✅ Token 使用量统计
- ✅ 成本追踪（动态计算）
- ✅ 预算进度条
- ✅ PR 列表和状态
- ✅ 活跃子代理数量
- ✅ 当前使用的模型显示

**截图位置**: 
- Dashboard 首页截图
- 预算状态截图
- PR 列表截图

---

### ✅ 4. 系统自主运行并提交 PR

**查看已提交的 PR**:
```bash
# 列出所有 PR
gh pr list --author [你的GitHub用户名] --state all --limit 10
```

**预期输出示例**:
```
#123  fix: correct typo in README.md           owner/repo   OPEN
#124  docs: update installation guide          owner/repo2  MERGED
#125  test: add unit tests for auth module     owner/repo3  OPEN
```

**验证点**:
- ✅ 至少提交 1 个 PR
- ✅ PR 描述清晰，包含修复说明
- ✅ 系统无人工干预自主运行
- ✅ 可处理审查反馈（如有）

**查看系统运行日志**:
```bash
# 查看最近的心跳循环
openclaw logs | grep "cycle-complete" | tail -10

# 查看活跃子代理
openclaw sessions list

# 查看预算累积
cat workspace/memory/budget-spent.txt
```

---

## 核心功能演示

### 功能 1: 模型配置灵活性

**演示步骤**:

1. **当前配置** (OpenAI GPT-4o-mini):
```bash
cat .env | grep LLM_PROVIDER
# 输出: LLM_PROVIDER=openai
```

2. **切换到其他模型** (演示配置，不实际运行):
```bash
# 编辑 .env，切换到 DeepSeek
# LLM_PROVIDER=deepseek
# LLM_MODEL=deepseek-chat
# LLM_API_KEY=sk-xxx
# LLM_BASE_URL=https://api.deepseek.com/v1
# LLM_COST_INPUT=0.14
# LLM_COST_OUTPUT=0.28

# 重启系统
bash scripts/restart.sh
```

3. **验证配置生成**:
```bash
# 查看生成的配置文件
cat ~/.openclaw/openclaw.json | jq '.models.providers'
```

**关键点**: 
- 无需修改任何 `.sh`、`.ts`、`.md` 文件
- 仅修改 `.env` 即可切换模型
- 成本自动按新模型计算

---

### 功能 2: 预算控制

**演示步骤**:

1. **查看当前预算**:
```bash
bash scripts/budget-status.sh
```

2. **模拟预算接近上限**:
```bash
# 手动设置已花费金额（仅演示）
echo "8.5" > workspace/memory/budget-spent.txt

# 再次查看状态
bash scripts/budget-status.sh
# 应显示警告: ⚠️  WARNING: 80% budget used
```

3. **模拟预算超限**:
```bash
# 设置超限金额
echo "10.5" > workspace/memory/budget-spent.txt

# 查看状态
bash scripts/budget-status.sh
# 应显示: ⚠️  BUDGET EXCEEDED - Gateway stopped
```

4. **重置预算**:
```bash
bash scripts/budget-reset.sh
# 输入 y 确认重置
```

**关键点**:
- 预算实时追踪
- 达到上限自动停止
- 可手动重置继续运行

---

### 功能 3: 系统自主运行

**演示步骤**:

1. **启动系统**:
```bash
bash scripts/restart.sh
```

2. **查看系统状态**:
```bash
# 查看网关状态
openclaw gateway status

# 查看活跃会话
openclaw sessions list

# 查看最近日志
openclaw logs | tail -50
```

3. **监控预算变化**:
```bash
# 每 10 秒刷新一次预算状态
watch -n 10 bash scripts/budget-status.sh
```

4. **查看 PR 提交**:
```bash
# 实时查看 PR 列表
watch -n 30 "gh pr list --author [你的用户名] --state open"
```

**关键点**:
- 系统 24/7 自主运行
- 无需人工干预
- 自动发现 issues、实现修复、提交 PR
- 预算控制防止超支

---

## 技术实现要点

### 修改的文件（共 4 个核心文件）

1. **scripts/restart.sh** (第 90-170 行)
   - 读取 LLM 环境变量
   - 动态生成 openclaw.json
   - 初始化预算追踪文件

2. **workspace/hooks/dashboard-reporter/handler.ts** (第 4-9 行, 560-600 行)
   - 动态读取成本配置
   - 累积预算到文件
   - 发送动态模型信息到 Dashboard

3. **.env.example** (完全重写)
   - 新增 LLM 配置变量
   - 新增预算控制变量
   - 提供多个模型配置示例

4. **workspace/HEARTBEAT.md** (步骤 0d)
   - 添加预算检查逻辑
   - 超限时停止循环

### 新增的文件（共 3 个脚本）

1. **scripts/budget-status.sh**
   - 显示预算状态
   - 彩色输出和警告

2. **scripts/budget-reset.sh**
   - 重置预算计数器
   - 交互式确认

3. **scripts/quick-test.sh**
   - 快速验证配置
   - 测试环境变量

---

## 验收话术

### 开场白

"我已完成 ClawOSS V11 的灵活 LLM 配置和预算控制改造。现在演示 4 个核心功能："

### 1. 模型配置灵活性

"通过 `.env` 文件，我可以配置任意 OpenAI 兼容的模型，无需修改代码。当前使用 OpenAI GPT-4o-mini，成本为每百万 tokens 输入 $0.15、输出 $0.6。"

**演示**: 展示 `.env` 文件和 `quick-test.sh` 输出

### 2. 预算控制

"我设置了 $10 的预算上限。当前已使用 $2.35，系统会在达到上限时自动停止，防止成本失控。"

**演示**: 运行 `bash scripts/budget-status.sh`

### 3. Dashboard 监控

"Dashboard 实时显示系统运行状态，包括预算进度、Token 使用量、当前模型和 PR 列表。"

**演示**: 打开 Dashboard 网页，展示各个面板

### 4. 自主运行与 PR 提交

"系统已自主运行 X 小时，提交了 Y 个 PR。所有操作无需人工干预，完全自动化。"

**演示**: 运行 `gh pr list` 和 `openclaw logs`

### 结束语

"改造完成后，ClawOSS 现在支持任意主流大模型，并具备完善的预算控制机制。系统可以标准化部署，自主运行，并在预算范围内持续贡献高质量 PR。"

---

## 常见问题

### Q1: 如何切换到其他模型？

**A**: 编辑 `.env` 文件，修改 `LLM_PROVIDER`、`LLM_MODEL`、`LLM_API_KEY` 等变量，然后运行 `bash scripts/restart.sh`。

### Q2: 预算超限后如何恢复？

**A**: 运行 `bash scripts/budget-reset.sh` 重置预算计数器，然后运行 `bash scripts/restart.sh` 重启系统。

### Q3: 如何验证配置是否正确？

**A**: 运行 `bash scripts/quick-test.sh`，它会检查所有必需的环境变量和配置文件。

### Q4: Dashboard 不显示预算信息怎么办？

**A**: 确保 `CLAW_API_KEY` 已设置，并且 `dashboard-reporter` hook 正常运行。检查日志：`openclaw logs | grep dashboard`

### Q5: 支持哪些模型？

**A**: 支持所有 OpenAI 兼容的 API，包括：
- OpenAI (GPT-4, GPT-4o, GPT-4o-mini)
- Anthropic (Claude 3.5 Sonnet, Claude 3 Opus)
- DeepSeek (DeepSeek Chat, DeepSeek Coder)
- OpenRouter (任意模型)
- Azure OpenAI
- 本地模型 (Ollama, LM Studio)

---

## 附录：完整配置示例

### OpenAI GPT-4o-mini (推荐用于测试)
```bash
LLM_PROVIDER=openai
LLM_MODEL=gpt-4o-mini
LLM_API_KEY=sk-xxx
LLM_BASE_URL=https://api.openai.com/v1
LLM_COST_INPUT=0.15
LLM_COST_OUTPUT=0.6
BUDGET_MAX_USD=10.0
```

### Anthropic Claude 3.5 Sonnet (推荐用于生产)
```bash
LLM_PROVIDER=anthropic
LLM_MODEL=claude-3-5-sonnet-20241022
LLM_API_KEY=sk-ant-xxx
LLM_BASE_URL=https://api.anthropic.com
LLM_CONTEXT_WINDOW=200000
LLM_MAX_TOKENS=8192
LLM_COST_INPUT=3.0
LLM_COST_OUTPUT=15.0
BUDGET_MAX_USD=50.0
```

### DeepSeek Chat (推荐用于成本优化)
```bash
LLM_PROVIDER=deepseek
LLM_MODEL=deepseek-chat
LLM_API_KEY=sk-xxx
LLM_BASE_URL=https://api.deepseek.com/v1
LLM_CONTEXT_WINDOW=64000
LLM_COST_INPUT=0.14
LLM_COST_OUTPUT=0.28
BUDGET_MAX_USD=5.0
```

---

**文档版本**: v1.0  
**创建时间**: 2026-04-23  
**作者**: Claude (Sonnet 4.6)
