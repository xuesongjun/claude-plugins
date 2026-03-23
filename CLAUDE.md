# Claude Code Plugins 开发规范

## 项目概述

个人 Claude Code 插件集合（marketplace 名：`xsj-plugins`），包含开发工作流 skills、代码质量工具和语言服务器集成。通过 Git 仓库跨机器同步。

## 项目结构

```
claude-plugins/
├── .claude-plugin/
│   └── marketplace.json          # marketplace 注册入口，定义所有插件
├── plugins/
│   ├── systemverilog-lsp/        # LSP 插件（无 plugin.json，配置在 marketplace.json 中）
│   │   ├── README.md
│   │   └── hooks/
│   │       ├── hooks.json        # hook 注册
│   │       └── verible-autofix.py
│   ├── dev-workflow/             # Skill 插件
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/*/SKILL.md
│   ├── test-studio/              # Skill 插件
│   └── code-quality/             # Skill 插件
└── README.md
```

## 关键约定

### 插件类型

| 类型 | 配置位置 | 示例 |
|------|----------|------|
| LSP 插件 | `marketplace.json` 的 `lspServers` 字段 | systemverilog-lsp |
| Skill 插件 | `plugins/<name>/.claude-plugin/plugin.json` + `skills/*/SKILL.md` | dev-workflow |

### 版本管理

- 版本号在 `marketplace.json` 中的 `version` 字段定义
- 遵循 Semantic Versioning：`MAJOR.MINOR.PATCH`
  - PATCH：bug 修复、小改进
  - MINOR：新功能（向后兼容）
  - MAJOR：破坏性变更
- **每次发布新功能必须更新版本号**，否则 Claude Code 不会刷新 cache

### Hook 开发

- Hook 文件放在 `plugins/<name>/hooks/` 目录下
- `hooks.json` 注册 hook 事件和脚本
- 脚本从 stdin 读取 JSON，通过 stdout 输出 JSON
- 使用 `python`（非 `python3`），兼容 Windows
- Verible 的 lint 输出在 **stderr**（非 stdout）

### Skill 开发

- 每个 skill 一个目录：`skills/<skill-name>/SKILL.md`
- SKILL.md 包含完整的 skill 定义和指令

## 注意事项

- 修改 `marketplace.json` 后必须更新相关插件的版本号
- 插件更新后用户需要通过 `/plugin` 重新安装并 `/reload-plugins`
- LSP 插件的 `CLAUDE_PLUGIN_ROOT` 指向 cache 目录，不是源仓库
- 提交信息使用中文
