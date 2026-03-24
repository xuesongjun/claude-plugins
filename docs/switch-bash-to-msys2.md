# Claude Code：将默认 Shell 切换为 MSYS2 Bash

## 背景

Claude Code 在 Windows 上默认使用 **Git Bash**（`C:\Program Files\Git\bin\bash.exe`）作为 Shell 环境。Git Bash 是一个精简的 bash 实现，存在以下局限：

- 自带的 perl 是精简版，缺少常用模块（如 `Pod::Usage`），导致部分工具（如 verilator）无法直接运行
- PATH 只继承 Windows 系统级路径，不含用户自定义工具路径
- alias 和 shell 函数在 Claude Code 的非交互式 bash 中不生效

切换到 **MSYS2 bash** 可以解决上述问题：
- 完整的 MSYS2 工具链（perl、pacman 等）
- 通过 `MSYS2_PATH_TYPE=inherit` 完整继承 Windows 用户 PATH
- 支持通过 pacman 按需安装 Linux 工具

---

## 前提条件

已安装 MSYS2，默认安装路径为 `C:\msys64`。

如未安装，可通过以下方式安装：

```powershell
# 方式一：winget（推荐，Windows 10/11 内置）
winget install MSYS2.MSYS2

# 方式二：scoop
scoop install msys2
```

---

## 配置步骤

### 第一步：修改 Claude Code 全局设置

编辑 `C:\Users\<用户名>\.claude\settings.json`，在 `env` 节点中添加三个配置项：

```json
{
  "env": {
    "SHELL": "C:\\msys64\\usr\\bin\\bash.exe",
    "BASH_ENV": "C:\\Users\\<用户名>\\.bashrc",
    "MSYS2_PATH_TYPE": "inherit"
  }
}
```

**配置说明：**

| 键 | 值 | 作用 |
|----|-----|------|
| `SHELL` | `C:\msys64\usr\bin\bash.exe` | 指定 Claude Code 使用的 Shell 可执行文件 |
| `BASH_ENV` | `C:\Users\<用户名>\.bashrc` | 非交互式 bash 启动时自动加载此文件（alias、export 等） |
| `MSYS2_PATH_TYPE` | `inherit` | 让 MSYS2 bash 完整继承 Windows 用户 PATH |

> **为什么用 `C:\msys64\usr\bin\bash.exe` 而不是 `C:\msys64\ucrt64.exe`？**
>
> `ucrt64.exe` 是终端窗口启动器，不是 Shell 本身。Claude Code 需要的是 bash 可执行文件。
> `usr\bin\bash.exe` 是 MSYS2 的 bash 本体，所有子环境（ucrt64、mingw64 等）共用同一个 bash。

> **为什么不设置 `MSYSTEM=UCRT64`？**
>
> 设置 `MSYSTEM` 后，MSYS2 会用子环境的 PATH 覆盖原有 PATH，导致 Windows 用户 PATH 中的工具（如自定义安装的 Git、Node.js 等）丢失。
> 不设置 `MSYSTEM`，配合 `MSYS2_PATH_TYPE=inherit`，bash 同时拥有 MSYS2 工具和完整的 Windows PATH，两全其美。

---

### 第二步：创建 `.bashrc` 文件（可选）

如需在 Claude Code 的 bash 环境中添加自定义配置，在 `C:\Users\<用户名>\.bashrc` 中写入：

```bash
# 示例：覆盖 Git Bash 自带的精简版 perl（如果仍需兼容 Git Bash）
# alias perl='/c/msys64/usr/bin/perl'

# 示例：添加其他自定义工具路径
# export PATH="/c/my-tools:$PATH"
```

> **注意**：配置了 `MSYS2_PATH_TYPE=inherit` 后，Windows 用户 PATH 已完整继承，通常不需要在 `.bashrc` 中手动添加路径。

---

### 第三步：重启 Claude Code

保存 `settings.json` 后，**完全重启** Claude Code（关闭所有窗口后重新打开）。

---

## 验证

重启后执行以下命令验证环境：

```bash
# 确认 bash 来源
echo $SHELL

# 确认 PATH 包含 Windows 用户路径
echo $PATH

# 验证工具可用性
which git && git --version
which node && node --version
which perl && perl --version | head -1
```

---

## 常见问题

### Q：为什么需要 `BASH_ENV`？

Claude Code 每次执行 Bash 命令时，会启动一个**新的非交互式 bash 进程**，然后立即退出。非交互式 bash 默认不读取 `~/.bashrc`。

`BASH_ENV` 是专门为非交互式 bash 设计的环境变量，指定的文件会在每次 bash 启动时自动加载。

### Q：`MSYS2_PATH_TYPE` 有哪些可选值？

| 值 | 行为 |
|----|------|
| `minimal`（默认） | 只继承 Windows 系统核心路径（System32 等） |
| `inherit` | **完整继承**父进程的 PATH（推荐） |
| `strict` | 完全不继承任何 Windows PATH |

### Q：切换后 Git 操作是否正常？

正常。MSYS2 bash 中可以使用：
- MSYS2 自带的 git（通过 `pacman -S mingw-w64-ucrt-x86_64-git` 安装）
- Windows PATH 中的 Git for Windows（`inherit` 模式下自动继承）

### Q：切换后能否使用 MSYS2 的 pacman 安装工具？

可以，但需要通过完整路径调用：

```bash
/c/msys64/usr/bin/pacman -S <package-name>
```

或在 MSYS2 终端（ucrt64.exe）中安装后，工具自动在 Claude Code 中可用（前提是工具路径在 PATH 中）。

---

## 恢复默认设置

如需切换回 Git Bash，删除 `settings.json` 中的三个配置项即可：

```json
{
  "env": {
    // 删除 SHELL、BASH_ENV、MSYS2_PATH_TYPE
  }
}
```

或直接使用备份文件（Claude Code 在修改 settings.json 前会自动生成备份）：

```
C:\Users\<用户名>\.claude\settings.json.backup.<时间戳>
```
