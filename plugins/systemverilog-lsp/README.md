# systemverilog-lsp

Verilog/SystemVerilog language server (Verible) for Claude Code, providing code intelligence, diagnostics, and formatting.

## Supported Extensions
`.v`, `.sv`, `.svh`, `.vh`

## Features

- **Diagnostics**: syntax errors + 70+ lint rules
- **Go to Definition**: cross-file symbol navigation (requires `verible.filelist`)
- **Find References**: cross-file reference lookup
- **Formatting**: full document / range formatting
- **Document Symbol**: module/class/function/variable outline
- **Code Action**: lint autofix + AUTO expansion (AUTOINST, etc.)
- **Rename**: symbol renaming
- **Hover**: experimental, requires `--lsp_enable_hover`

## Installation

### Via GitHub Releases (recommended)

Download pre-built binaries from [Verible Releases](https://github.com/chipsalliance/verible/releases), extract and add to PATH.

### Via Homebrew (macOS)
```bash
brew install verible
```

### Via package manager (Linux)
```bash
# Download latest release
wget https://github.com/chipsalliance/verible/releases/latest/download/verible-<version>-linux-static-x86_64.tar.gz
tar xzf verible-*.tar.gz
sudo cp verible-*/bin/* /usr/local/bin/
```

### Windows
Download from [Verible Releases](https://github.com/chipsalliance/verible/releases) and add `bin/` to PATH.

## Project Configuration

### Lint 规则配置

在项目根目录创建 `.rules.verible_lint` 文件，可自定义 LSP 的 lint 检查规则。LSP 会从被分析文件所在目录向上搜索该配置文件。

```
# .rules.verible_lint
# 无前缀或 + 前缀：启用规则，- 前缀：禁用规则
# 规则名=key:value 可配置规则参数

# 禁用行尾空格检查
-no-trailing-spaces

# 禁用参数命名风格检查
-parameter-name-style

# 设置最大行宽为 120
line-length=length:120
```

查看所有可用规则及默认配置：
```bash
verible-verilog-lint --print_rules_file
```

详细说明参见 [Verible Lint 文档](https://chipsalliance.github.io/verible/verilog_lint.html)。

### 跨文件功能

跨文件功能（跳转定义、查找引用）需要在项目根目录创建 `verible.filelist`：

```
// verible.filelist
rtl/top.sv
rtl/sub_module.v
inc/defines.svh
```

### 自动修复

插件内置 PostToolUse hook：Claude 每次编辑 Verilog 文件后，自动运行 `verible-verilog-lint --autofix=inplace` 修复可自动修复的 lint 警告（如 trailing spaces），无需手动处理。

## More Information
- [Verible GitHub](https://github.com/chipsalliance/verible)
- [Verible LS README](https://github.com/chipsalliance/verible/tree/master/verible/verilog/tools/ls)
