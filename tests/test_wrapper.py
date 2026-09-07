#!/usr/bin/env python3
import importlib.util
import importlib.machinery
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
loader = importlib.machinery.SourceFileLoader("agent_term_wrapper", str(ROOT / "bin" / "agent-term-wrapper"))
spec = importlib.util.spec_from_loader("agent_term_wrapper", loader)
module = importlib.util.module_from_spec(spec)
loader.exec_module(module)


class WrapperTests(unittest.TestCase):
    def test_codex_prompt_forms(self):
        cases = [
            (["/x/codex", "review the change"], "review the change"),
            (["/x/codex", "exec", "review the change"], "review the change"),
            (["/x/codex", "exec", "--model", "gpt-6", "review the change"], "review the change"),
            (["/x/codex", "-p", "work"], ""),
        ]
        for args, expected in cases:
            self.assertEqual(module.extract_cli_prompt(args), expected)

    def test_claude_prompt_forms(self):
        cases = [
            (["/x/claude"], ""),
            (["/x/claude", "code"], ""),
            (["/x/claude", "code", "explain this"], "explain this"),
            (["/x/claude", "explain this"], "explain this"),
            (["/x/claude", "-p", "explain this"], "explain this"),
        ]
        for args, expected in cases:
            self.assertEqual(module.extract_cli_prompt(args), expected)

    def test_query_filter_keeps_user_text_and_removes_replies(self):
        filt = module.TerminalQueryFilter()
        self.assertEqual(filt.feed(b"hello\x1b]10;rgb:d1d1/d7d7/dada\x07\r"), b"hello\r")
        self.assertEqual(filt.feed(b"\x1b[2;1Rworld"), b"world")
        self.assertEqual(filt.feed(b"\x1b[?62;1;2c"), b"")
        self.assertEqual(filt.feed(b"\x1b[?2026;2$y"), b"")

    def test_query_filter_preserves_app_queries(self):
        filt = module.TerminalQueryFilter(drop_titles=True)
        # DA1 device attributes queries
        self.assertEqual(filt.feed(b"\x1b[c"), b"\x1b[c")
        self.assertEqual(filt.feed(b"\x1b[0c"), b"\x1b[0c")
        # Color queries
        self.assertEqual(filt.feed(b"\x1b]10;?\x07"), b"\x1b]10;?\x07")
        self.assertEqual(filt.feed(b"\x1b]11;?\x07"), b"\x1b]11;?\x07")
        self.assertEqual(filt.feed(b"\x1b]11;?\x1b\\"), b"\x1b]11;?\x1b\\")

    def test_query_filter_handles_split_sequence(self):
        filt = module.TerminalQueryFilter()
        self.assertEqual(filt.feed(b"hello\x1b]10;rgb:d1"), b"hello")
        self.assertEqual(filt.feed(b"d1/d7d7/dada\x07!"), b"!")

    def test_display_filter_preserves_tui_styling(self):
        filt = module.TerminalQueryFilter(drop_titles=True)
        self.assertEqual(filt.feed(b"\x1b[31mred\x1b[0m"), b"\x1b[31mred\x1b[0m")

    def test_display_filter_drops_child_title_updates(self):
        filt = module.TerminalQueryFilter(drop_titles=True)
        self.assertEqual(filt.feed(b"before\x1b]0;herding_factor_dev\x07after"), b"beforeafter")
        self.assertEqual(filt.feed(b"\x1b]2;Codex\x1b\\ok"), b"ok")

    def test_empty_icon_does_not_add_leading_space(self):
        self.assertEqual(module.compose_title("", "Codex"), "Codex")
        self.assertEqual(module.compose_title("X", "Codex"), "X Codex")

    def test_title_input_filter_removes_antigravity_decrpm_and_cpr(self):
        filt = module.TitleInputFilter()
        raw = b"\x1b[?2026;2$y\x1b[?2027;0$y\xe4\xbd\xa0\xe6\x98\xaf\xe4\xbb\x80\xe4\xb9\x88\xe6\xa8\xa1\xe5\x9e\x8b\r"
        res = filt.feed(raw)
        self.assertEqual(res.decode("utf-8"), "你是什么模型\r")

    def test_title_input_filter_handles_split_decrpm(self):
        filt = module.TitleInputFilter()
        chunk1 = b"\x1b[?2026;2"
        chunk2 = b"$y\x1b[?2027;0$yhello\r"
        self.assertEqual(filt.feed(chunk1), b"")
        self.assertEqual(filt.feed(chunk2), b"hello\r")

    def test_title_input_filter_handles_bracketed_paste(self):
        filt = module.TitleInputFilter()
        raw = b"\x1b[200~\xe4\xbd\xa0\xe5\xa5\xbd\x1b[201~\r"
        self.assertEqual(filt.feed(raw).decode("utf-8"), "你好\r")

    def test_clean_title_sanitizes_decrpm_and_paste(self):
        self.assertEqual(module.clean_title("?2026;2$y[?2027;0$y你是什么模型"), "你是什么模型")
        self.assertEqual(module.clean_title("[?2026;2$y[?2027;0$y你是什么模型"), "你是什么模型")
        self.assertEqual(module.clean_title("[200~你是什么模型[201~"), "你是什么模型")
        self.assertEqual(module.clean_title("分析 2026 年年报"), "分析 2026 年年报")

    def test_is_zed_terminal_detection(self):
        import os
        orig = dict(os.environ)
        try:
            os.environ["TERM_PROGRAM"] = "zed"
            self.assertTrue(module.is_zed_terminal())
            os.environ["TERM_PROGRAM"] = "Apple_Terminal"
            os.environ.pop("ZED_TERM", None)
            os.environ.pop("ZED_ENVIRONMENT", None)
            self.assertFalse(module.is_zed_terminal())
        finally:
            os.environ.clear()
            os.environ.update(orig)


if __name__ == "__main__":
    unittest.main()
