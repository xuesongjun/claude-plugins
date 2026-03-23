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

For cross-file features (go-to-definition, find-references), create a `verible.filelist` in your project root:

```
// verible.filelist
rtl/top.sv
rtl/sub_module.v
inc/defines.svh
```

## More Information
- [Verible GitHub](https://github.com/chipsalliance/verible)
- [Verible LS README](https://github.com/chipsalliance/verible/tree/master/verible/verilog/tools/ls)
