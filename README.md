# Claude Plugins

Personal Claude Code plugin collection for cross-machine sync.

## 快速开始（新机器）

在 PowerShell 中运行一键配置脚本，自动安装 MSYS2、开发工具，并配置 Claude Code：

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/xuesongjun/claude-plugins/main/scripts/setup-dev-env.ps1" -OutFile "$env:TEMP\setup-dev-env.ps1"
& "$env:TEMP\setup-dev-env.ps1"
```

脚本完成后重启 Claude Code，再安装插件：

```
/plugin marketplace add xuesongjun/claude-plugins
/plugin install systemverilog-lsp@xsj-plugins
/plugin install dev-workflow@xsj-plugins
/plugin install code-quality@xsj-plugins
```

详细说明见 [docs/setup-dev-env.md](docs/setup-dev-env.md)。

## Installation

```bash
# Add marketplace
/plugin marketplace add xuesongjun/claude-plugins

# Install plugins
/plugin install dev-workflow@claude-plugins
/plugin install test-studio@claude-plugins
/plugin install code-quality@claude-plugins
/plugin install systemverilog-lsp@claude-plugins
```

## Plugins

### systemverilog-lsp

Verilog/SystemVerilog language server powered by [Verible](https://github.com/chipsalliance/verible). Provides diagnostics, go-to-definition, find-references, formatting, code actions, and rename.

**Prerequisite**: Install `verible-verilog-ls` and add to PATH. See [plugins/systemverilog-lsp/README.md](plugins/systemverilog-lsp/README.md).

**Features**:
- LSP 启动时自动启用 `--rules_config_search`，支持项目级 `.rules.verible_lint` 配置
- 内置 PostToolUse hook：编辑 Verilog 文件后自动运行 `verible-verilog-lint --autofix=inplace`，修复可自动修复的 lint 警告

### dev-workflow

| Skill | Description | Trigger |
|-------|-------------|---------|
| commit | Git commit with Chinese message | `/commit` |
| save-progress | Save progress to CLAUDE.md | `/save-progress` |
| sync-context | Restore previous dev context | `/sync-context` |
| run | Start Test Studio application | `/run` |

### test-studio

| Skill | Description |
|-------|-------------|
| fix-bug | Fix bugs following standard workflow |
| add-page | Add new page to Test Studio |
| add-reg-group | Add register group config |

### code-quality

| Skill | Description | Trigger |
|-------|-------------|---------|
| clean-code-architect | Architecture expert | New features, API design |
| quick-refactor | Refactoring assistant | `/quick-refactor` |
| test-master | Testing expert | `/test-master` |

## Docs

| 文档 | 说明 |
|------|------|
| [setup-dev-env.md](docs/setup-dev-env.md) | Windows 开发环境一键配置脚本使用说明 |
| [switch-bash-to-msys2.md](docs/switch-bash-to-msys2.md) | 将 Claude Code 默认 Shell 从 Git Bash 切换为 MSYS2 Bash |

## Structure

```
claude-plugins/
├── .claude-plugin/
│   └── marketplace.json            # marketplace 注册入口
├── docs/
│   ├── setup-dev-env.md            # 一键配置脚本说明
│   └── switch-bash-to-msys2.md     # 切换 Shell 指南
├── scripts/
│   └── setup-dev-env.ps1           # Windows 开发环境自动配置脚本
├── plugins/
│   ├── systemverilog-lsp/          # LSP 插件（配置在 marketplace.json）
│   │   ├── README.md
│   │   └── hooks/
│   │       ├── hooks.json          # PostToolUse hook 注册
│   │       └── verible-autofix.py  # 自动修复 lint 警告
│   ├── dev-workflow/               # Skill 插件
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/
│   ├── test-studio/                # Skill 插件
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/
│   └── code-quality/               # Skill 插件
│       ├── .claude-plugin/plugin.json
│       └── skills/
└── README.md
```
