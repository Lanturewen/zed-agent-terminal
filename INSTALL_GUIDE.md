# Zed Terminal Agent 身份与状态集成：迁移与安装指南

> 适用环境：macOS (Apple Silicon / Intel)、Zed 编辑器、zsh  
> 支持 Agent：**Codex**, **Claude Code**, **Antigravity**, **Grok**, **Pi**  
> 打包版本：`zed-agent-terminal-integration-1.0.0.tar.gz`

---

## 目录
- [一、功能特性](#一功能特性)
- [二、跨电脑迁移安装（3 步极简）](#二跨电脑迁移安装3-步极简)
- [三、Zed 终端与 UI 字体配置](#三zed-终端与-ui-字体配置)
- [四、各 Agent 测试验证指南](#四各-agent-测试验证指南)
- [五、已知问题与技术排错](#五已知问题与技术排错)
- [六、重新打包与完全卸载](#六重新打包与完全卸载)

---

## 一、功能特性

本集成方案为普通 Zed Terminal 标签页中的 CLI Agent 带来与 ACP 注册 Agent 一致的交互体验：

1. **统一品牌图标**：
   - 通过专用优化字体 `AgentIcons.ttf`，在 Zed 终端标签栏与侧边栏直接渲染对应 Agent 官方品牌矢量图标（已通过 1.30x 光学比例调整，视觉大小与中文字符、大写字母完美平衡）。
2. **首条提示词自适应命名**：
   - 交互式会话初始呈现 Agent 默认名（如 `Claude Code`、`Codex`、`Antigravity`）。
   - 用户在会话中敲入第一条问题后，标题自动捕获该问题（如 `你是什么模型`、`分析当前变更`），方便多会话标签管理。
3. **活动状态动态旋转指示器**：
   - Agent 生成内容、思考或调用工具时，标题动态播放 `⠋` 高帧率旋转动画。
   - 回合结束且无新输出超过 400ms 后，自动恢复静止纯净标题。
4. **终端底层协议免疫**：
   - 自动过滤 DECRQM/DECRPM（如同步输出模式探测回复 `?2026;2$y`）、CPR 光标回复、设备状态查询及 Bracketed Paste 标记，绝不污染用户标题。

---

## 二、跨电脑迁移安装（3 步极简）

### 1. 复制安装包
将工程根目录下的安装包拷贝到目标电脑：
- 归档包：`zed-agent-terminal-integration-1.0.0.tar.gz`
- 校验文件（可选）：`zed-agent-terminal-integration-1.0.0.tar.gz.sha256`

### 2. 解压并执行一键安装
在目标电脑的终端中执行：

```bash
# 1. 解压安装包
tar -xzf zed-agent-terminal-integration-1.0.0.tar.gz
cd zed-agent-terminal-integration

# 2. 一键安装
./install.sh
```

> **`install.sh` 做了什么？**
> - 自动将包装器安装至 `~/.local/bin/agent-term-wrapper`
> - 自动将优化后的矢量字体安装至 `~/Library/Fonts/AgentIcons.ttf`
> - 如果检测到 Pi Agent，自动将自动命名扩展同步至 `~/.pi/agent/extensions/auto-title.ts`
> - 在 `~/.zshrc` 末尾安全注入标记区块（原有文件自动生成 `.bak` 备份，幂等安全）

### 3. 刷新 Shell 并运行环境诊断
```bash
# 刷新当前 Shell
exec zsh

# 运行诊断脚本
./doctor.sh
```

看到输出如下即表示核心组件全部安装正常：
```text
platform: Darwin x86_64 (或 arm64)
home: /Users/<your_user>
wrapper: ok (~/.local/bin/agent-term-wrapper)
font: ok (~/Library/Fonts/AgentIcons.ttf)
shell block: ok
codex: /path/to/codex
claude: /path/to/claude
agy: /path/to/agy
grok: /path/to/grok
zed settings fallback: present
native terminal tab icon: unchanged (>_); requires upstream Zed terminal metadata support
```

---

## 三、Zed 终端与 UI 字体配置

目标电脑上的 Zed 需要配置字体回退（Font Fallbacks），使 Zed 的 UI 和终端能自动借由 `AgentIcons.ttf` 渲染私有区（PUA）图标。

### 方式 1：一键全自动配置（推荐）
`install.sh` 已经在安装过程中自动调用了配置脚本；如果你想单独配置或检查，直接运行：

```bash
./configure-zed.sh
```

> **自动化特性**：
> - 自动识别 `~/.config/zed/settings.json`（若不存在则自动创建）。
> - 自动创建 `.zed-agent.bak` 备份，绝不破坏原有注释和配置。
> - 智能增量合并，如果已配置则自动跳过。

### 方式 2：手动在 Zed 中配置
若想手动检查或修改：
1. 在 Zed 中按下快捷键 `Cmd + Shift + P`。
2. 输入 `open settings` 并回车，直接打开 `settings.json`。
3. 确保根对象中包含以下字体回退：

```jsonc
{
  // 终端文本字体回退
  "terminal": {
    "font_fallbacks": ["AgentIcons"]
  },
  // Zed 界面 UI（标签栏、侧边栏标题）字体回退
  "ui_font_fallbacks": ["AgentIcons"],
  // 编辑器缓冲区字体回退
  "buffer_font_fallbacks": ["AgentIcons"]
}
```

> **注意**：修改设置后建议通过 `Cmd + Q` 重启一次 Zed，确保 Zed 的 GPUI 字体缓存完全重新加载 `AgentIcons.ttf`。

---

## 四、各 Agent 测试验证指南

请在 Zed 中**打开一个全新的 Terminal 窗口**进行测试：

### 1. Antigravity 测试
```bash
agy
```
- **预期初始标题**：左侧为 Antigravity 拱门图标，文字为 `Antigravity`。
- **输入问题**：输入 `你是什么模型` 并回车。
- **预期效果**：
  - 生成过程中标题显示：`[Antigravity图标] ⠋ 你是什么模型`
  - 生成结束静止后显示：`[Antigravity图标] 你是什么模型`
  - **绝无** `?2026;2$y[?2027;0$y` 等转义字符残片。

### 2. Claude Code 测试
```bash
# 方式 A：标准启动
claude

# 方式 B：习惯用法启动（已支持跳过冗余 code 参数）
claude code
```
- **预期初始标题**：左侧为放大优化后的 Claude 官方星芒图标，文字为 **`Claude Code`**（不再错误显示为单个单词 `code`）。
- **图标尺寸**：星芒粗细饱满，高度与文本大写字母对齐，不再细小模糊。
- **输入问题**：输入提问后，标题立即自适应转换为该问题的文字。

### 3. Codex 测试
```bash
# 方式 A：交互式会话
codex

# 方式 B：一次性提示词
codex "审查当前代码"

# 方式 C：exec 子命令
codex exec "检查 git 状态"
```
- **预期初始标题**：左侧展示清晰饱满的 Codex 品牌螺旋花瓣图标。
- **生成过程**：回答期间动态展示 `⠋` 旋转指示器，结束后收敛至稳定会话标题。
- **与其它 Agent 体验一致**：彻底告别无图标与无动画的差异问题。

### 4. Grok 与 Pi 测试
```bash
grok
pi
```
- 正常展示 Grok 斜线品牌图标与 Pi 像素块品牌图标，动态更新生命周期标题。

---

## 五、已知问题与技术排错

| 现象 | 原因分析 | 解决方案 |
| :--- | :--- | :--- |
| **图标显示为一个方框带有问号或十六进制字符** | 字体尚未生效或 Zed 字体缓存未重载 | 1. 确认 `~/Library/Fonts/AgentIcons.ttf` 存在；<br>2. 确认 `~/.config/zed/settings.json` 中配置了 `"ui_font_fallbacks": ["AgentIcons"]`；<br>3. 完全退出 Zed (`Cmd+Q`) 后重新打开。 |
| **执行 `agy` / `claude` 报 `command not found`** | 目标机器上尚未安装该 Agent 的 CLI 本身 | 本集成包仅提供统一 PTY 包装器与视觉适配层，Agent 需自行安装（如 `npm i -g @openai/codex` 等）。 |
| **修改了 `~/.zshrc` 但未生效** | 当前终端会话未重新加载环境变量 | 在当前窗口执行 `exec zsh` 或重新开启新终端标签页。 |
| **Zed 标签最左侧依然有一个灰色的小 `>_`** | 属于 Zed 原生终端标签的内置 UI 组件 | 这是 Zed 当前架构下写死的内置图标，不可通过字体或 ANSI 修改；当前方案已通过侧边栏和标题文字首位完美实现图标呈现。 |

---

## 六、重新打包与完全卸载

### 1. 重新打包（打包当前工作区修改）
如果你在当前电脑上微调了代码并希望重新生成分发包：
```bash
./zed-agent-terminal-integration/package.sh
```
脚本会自动过滤掉 `__pycache__` 与临时文件，生成 `zed-agent-terminal-integration-1.0.0.tar.gz` 及其 SHA-256 校验文件。

### 2. 在目标电脑上完全卸载
如果需要彻底移除本地集成：
```bash
cd zed-agent-terminal-integration
./uninstall.sh
exec zsh
```
卸载脚本会自动清理：
- `~/.local/bin/agent-term-wrapper`
- `~/Library/Fonts/AgentIcons.ttf`
- `~/.pi/agent/extensions/auto-title.ts`
- 自动移除 `~/.zshrc` 中被管理的配置区块，并可还原之前生成的 `.bak` 备份。
