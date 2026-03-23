# Claude Plugins

Personal Claude Code plugin collection for cross-machine sync.

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

## Structure

```
claude-plugins/
├── .claude-plugin/
│   └── marketplace.json
├── plugins/
│   ├── systemverilog-lsp/
│   │   └── README.md
│   ├── dev-workflow/
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/
│   ├── test-studio/
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/
│   └── code-quality/
│       ├── .claude-plugin/plugin.json
│       └── skills/
└── README.md
```
