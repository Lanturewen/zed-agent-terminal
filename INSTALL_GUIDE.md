# Zed Terminal Agent 身份与状态集成：迁移与安装指南

> **适用环境**：macOS (Apple Silicon / Intel)、Zed 编辑器、zsh  
> **支持 Agent**：**Codex**, **Claude Code**, **Antigravity**, **Grok**, **Pi**  
> **开源仓库**：[Lanturewen/zed-agent-terminal](https://github.com/Lanturewen/zed-agent-terminal)  
> **打包版本**：`zed-agent-terminal-integration-1.0.0.tar.gz`

---

## 目录
- [一、功能特性](#一功能特性)
- [二、安装方式](#二安装方式)
  - [方式 A：通过 GitHub 仓库安装（推荐，便于后续 git pull 升级）](#方式-a通过-github-仓库安装推荐)
  - [方式 B：通过离线 Tarball 安装包安装](#方式-b通过离线-tarball-安装包安装)
- [三、Zed 终端与 UI 字体配置](#三zed-终端与-ui-字体配置)
- [四、多终端智能感知与优雅降级说明](#四多终端智能感知与优雅降级说明)
- [五、各 Agent 行为规范与测试验证](#五各-agent-行为规范与测试验证)
- [六、常见排错与已知问题 (FAQ)](#六常见排错与已知问题-faq)
- [七、重新打包与完全卸载](#七重新打包与完全卸载)

---

## 一、功能特性

本方案专为 Zed 编辑器的集成终端标签页设计，为常用 CLI AI Agent 提供接近 ACP 官方集成的原生使用体验：

1. **统一品牌矢量图标（精密光学标准化）**：
   - 专属字体 `AgentIcons.ttf` 将所有 5 个 Agent（Pi `\uF101`、Claude `\uF102`、Antigravity `\uF103`、Codex `\uF104`、Grok `\uF105`）的视觉高度严格统一为 **875 字体单位（87.5% em box）**。
   - 彻底解决早期版本中因过度缩放导致的 Codex 图标巨大化、以及 Claude 星芒在小字号下溢出被截断像星号 `*` 的问题，各品牌图标大小比例 100% 协调一致。
2. **多终端环境智能感知（Zero-Tofu 杜绝 `[?]` 乱码）**：
   - **在 Zed 终端内**：检测到 `TERM_PROGRAM=zed`，自动启用专属矢量品牌图标 + 动态旋转动画。
   - **在其他外部终端（Terminal.app / iTerm2 / Warp 等）**：由于 macOS 系统标题栏字体（SF Pro）无法渲染自定义私有区（PUA）字形，包装器自动隐藏 PUA 图标，只输出原生文字与标准 Braille 动态指示器（`⠋`），彻底消除系统窗口标题中的 `[?]` 豆腐块乱码！
3. **首条提示词自适应会话命名**：
   - 启动时稳定展示默认产品名（如 `Claude Code`、`Codex`、`Antigravity`），避免误将子命令（如 `claude code` 中的 `code`）当作提示词。
   - 用户在会话中敲入第一条问题后，标题自动捕获该问题文本（如 `你是什么模型`、`分析当前变更`），大幅改善多会话标签检索体验。
4. **活动状态动态旋转指示器**：
   - Agent 生成内容、思考或调用工具时，标题动态旋转播放 `⠋` 高帧率指示器。
   - 回合结束且无新输出超过 400ms 后，自动收敛恢复静止稳定标题。
5. **底层协议与别名安全防护**：
   - 自动过滤 DECRQM/DECRPM 同步探测回复（`?2026;2$y`）、CPR 光标回复、设备状态查询及 Bracketed Paste 标记，绝不污染标题。
   - 前置安全解除别名（`unalias`），防止既有的 shell alias 拦截包装器；多候选路径智能探测置于函数内部，绝不泄漏多余路径参数至目标 CLI。

---

## 二、安装方式

### 方式 A：通过 GitHub 仓库安装（推荐）

适合能访问 GitHub 的开发电脑，后续更新升级仅需 `git pull`。

```bash
# 1. 克隆代码仓库
git clone https://github.com/Lanturewen/zed-agent-terminal.git
cd zed-agent-terminal

# 2. 执行一键安装
./install.sh

# 3. 刷新当前 Shell
exec zsh

# 4. 验证安装状态
./doctor.sh
```

**后续更新只需**：
```bash
cd zed-agent-terminal
git reset --hard HEAD && git pull
./install.sh
exec zsh
```

---

### 方式 B：通过离线 Tarball 安装包安装

适合离线电脑或离线部署场景。

```bash
# 1. 解压安装包
tar -xzf zed-agent-terminal-integration-1.0.0.tar.gz
cd zed-agent-terminal-integration

# 2. 一键安装
./install.sh

# 3. 刷新当前 Shell
exec zsh

# 4. 运行环境诊断
./doctor.sh
```

> **`install.sh` 自动化处理内容**：
> 1. 将通用 PTY 核心包装器安装至 `~/.local/bin/agent-term-wrapper`。
> 2. 将标准化矢量字体安装至 `~/Library/Fonts/AgentIcons.ttf`。
> 3. 若检测到 Pi Agent，自动安装/更新 `~/.pi/agent/extensions/auto-title.ts`。
> 4. 自动调用 `bin/configure-zed`，在 `~/.config/zed/settings.json` 中注入字体回退（自动备份为 `.zed-agent.bak`，保留所有 JSONC 注释）。
> 5. 在 `~/.zshrc` 末尾安全维护受管 shell 挂载块。

---

## 三、Zed 终端与 UI 字体配置

安装完成后，Zed 会通过字体回退（Font Fallbacks）借由 `AgentIcons.ttf` 显示 Agent 图标。

### 1. 自动配置（已内置）
`install.sh` 执行期间已自动调用内置工具完成合并；若需要手动触发配置检查，直接运行：
```bash
./configure-zed.sh
```

### 2. 手动配置确认（可选）
在 Zed 中按下 `Cmd + Shift + P`，输入 `open settings` 打开 `settings.json`，确保存在以下回退配置：

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

> **提示**：配置完成后建议通过 `Cmd + Q` 完全重启一次 Zed，确保 Zed 的 GPUI 字体缓存完全重新载入。

---

## 四、多终端智能感知与优雅降级说明

| 运行环境 | 窗口/标签栏标题渲染效果 | 原理说明 |
| :--- | :--- | :--- |
| **Zed 集成终端** | `[Agent矢量图标] ⠋ 你是什么模型` | Zed 已配置 `ui_font_fallbacks: ["AgentIcons"]`，正常渲染专属品牌图标。 |
| **macOS 自带 Terminal.app** | `⠋ 你是什么模型` | macOS 系统窗口标题栏强制使用系统 SF Pro 字体，无法加载 PUA。包装器**自动省略 PUA 图标**，杜绝 `[?]` 豆腐块，保持原生清爽。 |
| **Warp / iTerm2 / Ghostty** | `⠋ 你是什么模型` | 自动感知非 Zed 环境，优雅降级为纯文本与标准 Braille 动态指示器。 |

> **强制显示模式**：若你在其他终端（如 iTerm2）中也专门配置了 `AgentIcons` 字体并希望强制输出 PUA 图标，可设置环境变量 `export AGENT_TERM_FORCE_ICON=1`。

---

## 五、各 Agent 行为规范与测试验证

在 Zed 中**打开全新 Terminal 标签页**（或执行 `exec zsh`）进行验证：

### 1. Codex
```bash
codex
```
- **初始标题**：左侧展示 OpenAI 螺旋花瓣图标，文字为 `Codex`。图标大小与文字完全协调，不再巨大化。
- **输入提问**：输入 `你是什么模型` 并回车，标题立即动态轮播 `⠋ 你是什么模型`，回答完毕后收敛为静止标题。
- **纯净传参**：无参数输入时纯净启动，不会再误报 `unexpected argument found`。

### 2. Claude Code
```bash
claude
# 或
claude code
```
- **初始标题**：展示舒展平衡的 Claude 官方星芒图标，文字稳定为 `Claude Code`（跳过冗余 `code` 参数）。
- **图标渲染**：不再被误缩放或截断为紧凑的 `*` 字符，外形饱满清晰。
- **多路径自愈**：无论 Claude 安装在 `~/.local/bin`、`/opt/homebrew/bin` 还是 npm 全局目录，均可自动探测启动并注入标题与指示器。

### 3. Antigravity (`agy`)
```bash
agy
```
- **初始标题**：展示 Antigravity 拱门图标，文字为 `Antigravity`。
- **输入提问**：彻底免疫 DECRPM 探测序列，绝无 `?2026;2$y[?2027;0$y` 乱码残留。

### 4. Pi Agent (`pi`)
```bash
pi
```
- 自动挂载 `auto-title.ts` 扩展，在 Zed 中展示 Pi 品牌图标，在外部终端自动降级为无豆腐块的清爽标题。

---

## 六、常见排错与已知问题 (FAQ)

### Q1：在其他终端（如 Terminal.app、Warp）中标题出现 `[?]` 标志？
- **原因**：早期版本在所有终端无差别输出 PUA 私有字符（`\uF101`~`\uF105`），而系统原生终端标题栏只认系统字体，找不到字符就会显示为缺字方块 `[?]`。
- **解决**：拉取最新版代码并运行 `./install.sh && exec zsh`，新版本已加入环境感知，在非 Zed 终端会自动隐藏私有区图标，彻底消除 `[?]` 豆腐块。

### Q2：运行 `git pull` 报错 `error: Your local changes to the following files would be overwritten by merge`？
- **原因**：本地克隆目录中的 `shell/zed-agent.zsh` 或其他文件被修改过，Git 阻止了合并。
- **解决**：直接重置本地未提交改动并重新拉取：
  ```bash
  git reset --hard HEAD && git pull && ./install.sh && exec zsh
  ```

### Q3：运行 `codex` 报错 `error: unexpected argument '.../codex' found`？
- **原因**：旧版多路径探测把候选路径直接放在了参数列表里，参数未被清除导致泄漏给 `codex`。
- **解决**：最新版已将候选路径探测收敛在函数内部静默执行，更新到最新版后执行 `exec zsh` 即可彻底恢复正常。

### Q4：在 Zed 终端输入 `claude` 依然显示 `herding_factor_dev — Claude`，没有图标和旋转动画？
- **原因**：
  1. 当前终端标签页是在安装集成脚本之前打开的，没有加载最新的 shell 函数；
  2. 或者之前本地配置过 `alias claude=...` 绕过了函数。
- **解决**：新版本已加入 `unalias claude` 保护；请在当前窗口执行 `exec zsh` 或**新开一个 Zed 终端标签页**即可生效。

### Q5：Zed 标签最左侧依然有一个灰色的小 `>_`？
- **原因**：这是 Zed 目前写死的内置 Terminal Tab UI 图标，不可通过 ANSI 转义或字体回退替换。
- **状态**：当前方案已在侧边栏会话列表和标签页标题首位完美呈现品牌图标；彻底替换最左侧小 `>_` 需等待 Zed 上游支持 [Feature Request / Discussion](https://github.com/zed-industries/zed/discussions)。

---

## 七、重新打包与完全卸载

### 1. 重新生成离线安装包
```bash
./package.sh
```
自动剔除 `__pycache__` 与临时文件，生成 `zed-agent-terminal-integration-1.0.0.tar.gz` 和 `.sha256` 校验文件。

### 2. 完全卸载
```bash
./uninstall.sh
exec zsh
```
自动清除所有受管二进制、字体、Pi 扩展及 `~/.zshrc` 中的挂载区块。
