# Windows 开发环境自动配置指南

本文档说明如何使用 `setup-dev-env.ps1` 在新 Windows 机器上一键配置 Claude Code 开发环境。

## 配置内容

脚本自动完成以下操作：

| 步骤 | 内容 | 说明 |
|------|------|------|
| 1 | 安装 MSYS2 | 通过 winget 安装，默认路径 `C:\msys64` |
| 2 | 安装 MSYS2 包 | `verilator`（ucrt64 版本） |
| 3 | 配置用户 PATH | 将 `C:\msys64\usr\bin` 和 `C:\msys64\ucrt64\bin` 加入用户 PATH |
| 4 | 配置 Claude Code | 修改 `settings.json`，切换 Shell 为 MSYS2 bash |
| 5 | 创建 `~/.bashrc` | 重定向 HOME 到 Windows 用户目录，供 Claude Code 非交互式 bash 加载 |

脚本具备**幂等性**：重复执行不会覆盖已有配置。

---

## 快速开始

### 方式一：直接运行（推荐）

在 PowerShell 中执行：

```powershell
# 设置执行策略（如未设置）
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 下载并运行
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/xuesongjun/claude-plugins/main/scripts/setup-dev-env.ps1" -OutFile "$env:TEMP\setup-dev-env.ps1"
& "$env:TEMP\setup-dev-env.ps1"
```

### 方式二：克隆仓库后运行

```powershell
git clone https://github.com/xuesongjun/claude-plugins.git
cd claude-plugins
.\scripts\setup-dev-env.ps1
```

---

## 参数说明

```powershell
.\setup-dev-env.ps1 [参数]
```

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `-Msys2Path` | string | `C:\msys64` | MSYS2 安装路径 |
| `-SkipMsys2Install` | switch | - | 跳过 MSYS2 安装 |
| `-SkipPackages` | switch | - | 跳过 pacman 包安装 |
| `-SkipClaudeConfig` | switch | - | 跳过 Claude Code 配置 |

### 使用示例

```powershell
# 仅配置 Claude Code（MSYS2 和工具已手动安装好）
.\setup-dev-env.ps1 -SkipMsys2Install -SkipPackages

# MSYS2 安装在非默认路径
.\setup-dev-env.ps1 -Msys2Path "D:\msys64"

# 跳过 Claude Code 配置（只安装工具）
.\setup-dev-env.ps1 -SkipClaudeConfig
```

---

## settings.json 变更说明

脚本会在 `~/.claude/settings.json` 的 `env` 节点中写入以下三项：

```json
{
  "env": {
    "SHELL": "C:\\msys64\\usr\\bin\\bash.exe",
    "BASH_ENV": "C:\\Users\\<用户名>\\.bashrc",
    "MSYS2_PATH_TYPE": "inherit"
  }
}
```

| 键 | 作用 |
|----|------|
| `SHELL` | 指定 Claude Code 使用 MSYS2 bash 而非 Git Bash |
| `BASH_ENV` | 非交互式 bash 启动时自动加载 `.bashrc`（alias、export 等） |
| `MSYS2_PATH_TYPE` | 设为 `inherit` 使 bash 完整继承 Windows 用户 PATH |

原有配置不会被删除，只追加/更新这三项。运行前自动备份原文件：
```
~/.claude/settings.json.backup.20260324_120000
```

---

## 脚本完成后的手动步骤

### 1. 安装 Verible（LSP 支持）

Verible 不在 MSYS2 包管理中，需手动安装：

1. 访问 [Verible Releases](https://github.com/chipsalliance/verible/releases) 下载 Windows 预编译包
2. 解压到 `C:\tools\verible\`
3. 将 `C:\tools\verible` 加入系统用户 PATH

验证：
```powershell
verible-verilog-ls --version
```

### 2. 重启 Claude Code

**必须完全重启**（关闭所有 Claude Code 窗口后重新打开），配置才能生效。

### 3. 安装 Claude Code 插件

```
/plugin marketplace add xuesongjun/claude-plugins
/plugin install systemverilog-lsp@xsj-plugins
/plugin install dev-workflow@xsj-plugins
/plugin install code-quality@xsj-plugins
```

---

## 验证环境

重启 Claude Code 后，在对话中输入以下命令验证：

```bash
# 验证 Shell 环境
echo $SHELL          # 应输出 /usr/bin/bash（MSYS2）
echo $HOME           # 应输出 /c/Users/<用户名>（Windows 用户目录）
which git            # 应找到 git
which verilator      # 应找到 verilator
which verible-verilog-ls  # 应找到 verible-verilog-ls（如已安装）

# 验证 PATH 继承
which node           # 如果 Node.js 在 Windows PATH 中，应能找到

# 验证 git 配置继承
git config --global --list  # 应能读取 Windows 用户目录下的 .gitconfig
```

---

## 常见问题

### Q：winget 安装 MSYS2 失败

可能原因：
- 网络问题或代理未配置
- winget 版本过旧

解决方案：手动从 [msys2.org](https://www.msys2.org/) 下载安装包，安装到 `C:\msys64`，然后运行：

```powershell
.\setup-dev-env.ps1 -SkipMsys2Install
```

### Q：pacman 安装包时网络超时

在 MSYS2 终端中切换镜像：

```bash
# 编辑镜像配置（以 ucrt64 为例）
nano /etc/pacman.d/mirrorlist.ucrt64

# 将以下镜像移到最前面（推荐清华镜像）
Server = https://mirrors.tuna.tsinghua.edu.cn/msys2/mingw/ucrt64/
```

然后重新运行脚本。

### Q：执行脚本报"不允许运行脚本"

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Q：settings.json 已有其他配置，会被覆盖吗？

不会。脚本只追加/更新 `SHELL`、`BASH_ENV`、`MSYS2_PATH_TYPE` 三项，其他所有配置（API key、model、plugins 等）保持不变。

---

## 参考文档

- [切换 Claude Code Shell 为 MSYS2 详细说明](switch-bash-to-msys2.md)
- [Verible 官方文档](https://chipsalliance.github.io/verible/)
- [MSYS2 官网](https://www.msys2.org/)
