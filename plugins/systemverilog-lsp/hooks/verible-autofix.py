#!/usr/bin/env python3
"""PostToolUse hook: auto-fix Verible lint warnings after editing .v/.sv/.svh/.vh files."""
import json
import subprocess
import sys
import shutil

VERILOG_EXTENSIONS = (".v", ".sv", ".svh", ".vh")

def main():
    try:
        input_data = json.load(sys.stdin)
        tool_input = input_data.get("tool_input", {})
        file_path = tool_input.get("file_path", "")

        if not file_path or not file_path.lower().endswith(VERILOG_EXTENSIONS):
            print(json.dumps({}))
            return

        lint_cmd = shutil.which("verible-verilog-lint")
        if not lint_cmd:
            print(json.dumps({}))
            return

        result = subprocess.run(
            [lint_cmd, "--rules_config_search", "--autofix=inplace", file_path],
            capture_output=True, text=True, timeout=30
        )

        if result.returncode == 0:
            print(json.dumps({}))
        else:
            # returncode != 0 means there are unfixable warnings, not an error
            print(json.dumps({
                "suppressOutput": True
            }))

    except Exception:
        print(json.dumps({}))

    sys.exit(0)

if __name__ == "__main__":
    main()
