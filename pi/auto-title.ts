/**
 * Auto-title & Live-Activity extension for Pi.
 *
 * 1. Automatically generates a concise conversation name from the user's first prompt.
 * 2. While Pi is thinking or running tools, runs a high-fps live animation in the
 *    terminal title (visible in Zed's terminal sidebar, bottom dock, iTerm2, etc.):
 *    e.g. "⠋ [思考中 5s] 为什么pi...", "⚡ [工具: edit 2s] 为什么pi..."
 * 3. Updates Pi's in-terminal working indicator and message so internal progress is obvious.
 * 4. When finished, restores a clean completion title: "✓ [14s] 为什么pi..."
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const TITLE_MAX_LEN = 35;
const SPINNER_FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
// U+F101 is the official pi-acp.svg compiled into ~/Library/Fonts/AgentIcons.ttf
const AGENT_ICON = "\uF101";

export function cleanTitle(text: string | null | undefined): string | null {
  if (!text) return null;

  let cleaned = text.replace(/\r\n/g, "\n");

  // 1. 过滤 Zed / ACP 注入的上下文标记
  cleaned = cleaned.replace(/\[(?:Context|Embedded Context|Audio)\][^\n]*/g, "");
  cleaned = cleaned.replace(/<context[\s\S]*?<\/context>/gi, "");

  // 2. 过滤剪贴板临时图片路径
  cleaned = cleaned.replace(
    /\/?(?:var\/folders|tmp|private\/var)\/[a-zA-Z0-9_.\/-]+\.(?:png|jpg|jpeg|gif|webp)/gi,
    " "
  );
  cleaned = cleaned.replace(
    /[a-zA-Z0-9_.\/-]*pi-clipboard-[a-f0-9-]+\.(?:png|jpg|jpeg|gif|webp)/gi,
    " "
  );

  // 3. 过滤 file:// URLs
  cleaned = cleaned.replace(/file:\/\/\S+/g, "");

  const lines = cleaned
    .split("\n")
    .map((l) => l.trim())
    .filter(Boolean);

  let candidate: string | null = null;
  for (let line of lines) {
    if (line.startsWith("```")) continue;
    // 去除斜杠命令前缀（如 /review docs/... -> review docs/...）
    if (/^\/[a-zA-Z0-9_-]+(?:\s|$)/.test(line)) {
      line = line.slice(1);
    }
    if (line) {
      candidate = line;
      break;
    }
  }

  if (candidate) {
    // 处理拖拽单个文件路径：提取纯文件名
    candidate = candidate.replace(
      /^['"]?(?:\/(?:Users|home|var|tmp|private|root)\/[^\s'"]*\/)?([^\s'"/]+\.[a-zA-Z0-9_-]+)['"]?\s*[:：\-—]?\s*/,
      (match, filename, _offset, fullStr) => {
        if (match.trim() === fullStr.trim()) return filename;
        return filename + ": ";
      }
    );

    let collapsed = candidate.replace(/\s+/g, " ").trim();
    if (
      (collapsed.startsWith('"') && collapsed.endsWith('"')) ||
      (collapsed.startsWith("'") && collapsed.endsWith("'"))
    ) {
      collapsed = collapsed.slice(1, -1).trim();
    }

    if (collapsed) {
      return collapsed.length > TITLE_MAX_LEN
        ? collapsed.slice(0, TITLE_MAX_LEN).trimEnd() + "…"
        : collapsed;
    }
  }

  // 后备方案：从文本中提取提到的文件名
  const fileMatch = text.match(/(?:file:\/\/|\/)([^\s\?#/]+\.[a-zA-Z0-9_-]+)/);
  if (fileMatch && fileMatch[1]) {
    try {
      const decoded = decodeURIComponent(fileMatch[1]).trim();
      if (decoded) {
        return decoded.length > TITLE_MAX_LEN
          ? decoded.slice(0, TITLE_MAX_LEN).trimEnd() + "…"
          : decoded;
      }
    } catch {
      return fileMatch[1].length > TITLE_MAX_LEN
        ? fileMatch[1].slice(0, TITLE_MAX_LEN).trimEnd() + "…"
        : fileMatch[1];
    }
  }

  return null;
}

function extractUserText(content: unknown): string {
  if (typeof content === "string") return content;
  if (Array.isArray(content)) {
    return content
      .filter((c: any) => c && c.type === "text" && typeof c.text === "string")
      .map((c: any) => c.text)
      .join(" ");
  }
  return "";
}

function sendTerminalTitle(title: string) {
  if (process.stdout.isTTY) {
    try {
      process.stdout.write(`\x1b]0;${title}\x07\x1b]2;${title}\x07`);
    } catch {}
  }
}

export default function (pi: ExtensionAPI) {
  let baseTitle = "Pi Agent";
  let activeTimer: NodeJS.Timeout | null = null;
  let frameIdx = 0;

  function stopAnimation() {
    if (activeTimer) {
      clearInterval(activeTimer);
      activeTimer = null;
    }
  }

  function startAnimation(ctx: ExtensionContext) {
    stopAnimation();
    frameIdx = 0;
    activeTimer = setInterval(() => {
      const frame = SPINNER_FRAMES[frameIdx % SPINNER_FRAMES.length];
      frameIdx++;
      const title = `${AGENT_ICON} ${frame} ${baseTitle}`;
      sendTerminalTitle(title);
      ctx.ui.setTitle(title);
    }, 80);
  }

  function setCleanTitle(ctx: ExtensionContext) {
    stopAnimation();
    const title = `${AGENT_ICON} ${baseTitle}`;
    sendTerminalTitle(title);
    ctx.ui.setTitle(title);
  }

  // 1. 会话启动/恢复时同步标题
  pi.on("session_start", async (_event, ctx) => {
    const existingName = pi.getSessionName();
    if (existingName) {
      baseTitle = existingName;
      setCleanTitle(ctx);
      return;
    }

    if (ctx.sessionManager) {
      try {
        const entries = ctx.sessionManager.getEntries();
        for (const entry of entries) {
          if (entry.type === "message" && entry.message.role === "user") {
            const rawText = extractUserText(entry.message.content);
            const title = cleanTitle(rawText);
            if (title) {
              baseTitle = title;
              pi.setSessionName(title);
              setCleanTitle(ctx);
              break;
            }
          }
        }
      } catch {}
    }
  });

  // 2. 发送首条提示词时自动命名
  pi.on("before_agent_start", async (event, ctx) => {
    const existingName = pi.getSessionName();
    if (!existingName) {
      const title = cleanTitle(event.prompt);
      if (title) {
        baseTitle = title;
        pi.setSessionName(title);
      }
    } else {
      baseTitle = existingName;
    }
  });

  // 3. Agent 开始执行：启动动态旋转动画
  pi.on("agent_start", async (_event, ctx) => {
    startAnimation(ctx);
    ctx.ui.setWorkingIndicator({
      frames: SPINNER_FRAMES,
      intervalMs: 80,
    });
    ctx.ui.setWorkingMessage("Working...");
  });

  // 4. 用户手动通过 /name 命名时，即时响应
  pi.on("session_info_changed", async (event, ctx) => {
    if (event.name) {
      baseTitle = event.name;
      if (!activeTimer) {
        setCleanTitle(ctx);
      }
    }
  });

  // 5. 对话回合结束：停止动画，恢复静止标题
  pi.on("agent_settled", async (_event, ctx) => {
    setCleanTitle(ctx);
  });
}
