#Requires -Version 5.1
<#
.SYNOPSIS
    Windows Claude Code 开发环境自动配置脚本

.DESCRIPTION
    自动完成以下配置：
    1. 检测并安装 MSYS2（如未安装）
    2. 通过 pacman 安装必要工具（git、verilator）
    3. 配置 Claude Code settings.json（切换 bash 为 MSYS2）
    4. 创建 ~/.bashrc

    脚本具备幂等性：重复执行不会破坏已有配置。

.PARAMETER Msys2Path
    MSYS2 安装路径，默认为 C:\msys64

.PARAMETER SkipMsys2Install
    跳过 MSYS2 安装（已手动安装时使用）

.PARAMETER SkipPackages
    跳过 pacman 包安装

.PARAMETER SkipClaudeConfig
    跳过 Claude Code settings.json 配置

.EXAMPLE
    # 完整安装
    .\setup-dev-env.ps1

    # 仅配置 Claude Code（跳过 MSYS2 和包安装）
    .\setup-dev-env.ps1 -SkipMsys2Install -SkipPackages

    # 指定自定义 MSYS2 路径
    .\setup-dev-env.ps1 -Msys2Path "D:\msys64"

.NOTES
    运行前请确保 PowerShell 执行策略允许运行脚本：
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
#>

[CmdletBinding()]
param(
    [string]$Msys2Path = "C:\msys64",
    [switch]$SkipMsys2Install,
    [switch]$SkipPackages,
    [switch]$SkipClaudeConfig
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ─────────────────────────────────────────────
# 辅助函数
# ─────────────────────────────────────────────

function Write-Step {
    param([string]$Message)
    Write-Host "`n▶ $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "  ✓ $Message" -ForegroundColor Green
}

function Write-Skipped {
    param([string]$Message)
    Write-Host "  - $Message (已跳过)" -ForegroundColor DarkGray
}

function Write-Warning2 {
    param([string]$Message)
    Write-Host "  ! $Message" -ForegroundColor Yellow
}

function Write-Fail {
    param([string]$Message)
    Write-Host "  ✗ $Message" -ForegroundColor Red
}

# ─────────────────────────────────────────────
# 步骤 1：检测 / 安装 MSYS2
# ─────────────────────────────────────────────

function Install-Msys2 {
    Write-Step "检测 MSYS2"

    $bashExe = Join-Path $Msys2Path "usr\bin\bash.exe"

    if (Test-Path $bashExe) {
        Write-Success "MSYS2 已安装：$Msys2Path"
        return
    }

    if ($SkipMsys2Install) {
        Write-Fail "MSYS2 未找到（路径：$Msys2Path），且指定了 -SkipMsys2Install"
        throw "请先安装 MSYS2 后重试，或通过 -Msys2Path 指定正确路径"
    }

    Write-Host "  MSYS2 未安装，正在通过 winget 安装..." -ForegroundColor Yellow

    # 检查 winget 是否可用
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Fail "winget 不可用"
        Write-Host @"

  请手动安装 MSYS2：
  1. 访问 https://www.msys2.org/ 下载安装包
  2. 安装到 $Msys2Path
  3. 重新运行此脚本

"@ -ForegroundColor Yellow
        throw "缺少 winget，无法自动安装 MSYS2"
    }

    winget install --id MSYS2.MSYS2 --location $Msys2Path --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        throw "winget 安装 MSYS2 失败（退出码：$LASTEXITCODE）"
    }

    # 等待安装完成
    $timeout = 60
    $elapsed = 0
    while (-not (Test-Path $bashExe) -and $elapsed -lt $timeout) {
        Start-Sleep -Seconds 2
        $elapsed += 2
    }

    if (-not (Test-Path $bashExe)) {
        throw "MSYS2 安装完成但找不到 $bashExe，请检查安装路径"
    }

    Write-Success "MSYS2 安装完成：$Msys2Path"
}

# ─────────────────────────────────────────────
# 步骤 2：安装 MSYS2 包
# ─────────────────────────────────────────────

function Install-Msys2Packages {
    Write-Step "安装 MSYS2 包"

    if ($SkipPackages) {
        Write-Skipped "pacman 包安装"
        return
    }

    $pacman = Join-Path $Msys2Path "usr\bin\pacman.exe"
    if (-not (Test-Path $pacman)) {
        throw "找不到 pacman：$pacman"
    }

    # 需要安装的包列表
    # Key = 包名，Value = 安装后的可执行文件路径（用于检测是否已安装）
    $packages = [ordered]@{
        "mingw-w64-ucrt-x86_64-git"        = "ucrt64\bin\git.exe"
        "mingw-w64-ucrt-x86_64-verilator"  = "ucrt64\bin\verilator_bin.exe"
    }

    foreach ($pkg in $packages.GetEnumerator()) {
        $binPath = Join-Path $Msys2Path $pkg.Value
        if (Test-Path $binPath) {
            Write-Skipped "$($pkg.Key) 已安装"
            continue
        }

        Write-Host "  安装 $($pkg.Key)..." -ForegroundColor Yellow
        & $pacman -S --noconfirm $pkg.Key
        if ($LASTEXITCODE -ne 0) {
            Write-Warning2 "$($pkg.Key) 安装失败（退出码：$LASTEXITCODE），继续执行"
        } else {
            Write-Success "$($pkg.Key) 安装完成"
        }
    }
}

# ─────────────────────────────────────────────
# 步骤 3：配置 Claude Code settings.json
# ─────────────────────────────────────────────

function Set-ClaudeConfig {
    Write-Step "配置 Claude Code settings.json"

    if ($SkipClaudeConfig) {
        Write-Skipped "Claude Code 配置"
        return
    }

    $claudeDir   = Join-Path $env:USERPROFILE ".claude"
    $settingsFile = Join-Path $claudeDir "settings.json"
    $bashExe     = Join-Path $Msys2Path "usr\bin\bash.exe"
    $bashrcFile  = Join-Path $env:USERPROFILE ".bashrc"

    # 确保 .claude 目录存在
    if (-not (Test-Path $claudeDir)) {
        New-Item -ItemType Directory -Path $claudeDir | Out-Null
    }

    # 读取或初始化 settings.json
    if (Test-Path $settingsFile) {
        # 备份原文件
        $timestamp  = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupFile = "$settingsFile.backup.$timestamp"
        Copy-Item $settingsFile $backupFile
        Write-Success "已备份原配置：$backupFile"

        $settings = Get-Content $settingsFile -Raw | ConvertFrom-Json
    } else {
        $settings = [PSCustomObject]@{}
    }

    # 确保 env 节点存在
    if (-not ($settings.PSObject.Properties.Name -contains "env")) {
        $settings | Add-Member -MemberType NoteProperty -Name "env" -Value ([PSCustomObject]@{})
    }

    # 写入三个配置项
    $envNode = $settings.env
    $newEnv = @{
        "SHELL"             = $bashExe
        "BASH_ENV"          = $bashrcFile
        "MSYS2_PATH_TYPE"   = "inherit"
    }

    foreach ($key in $newEnv.Keys) {
        if ($envNode.PSObject.Properties.Name -contains $key) {
            $envNode.$key = $newEnv[$key]
        } else {
            $envNode | Add-Member -MemberType NoteProperty -Name $key -Value $newEnv[$key]
        }
    }

    # 写回文件（保留 UTF-8 无 BOM，缩进 2 空格）
    $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsFile -Encoding UTF8

    Write-Success "settings.json 已更新"
    Write-Host "    SHELL            = $bashExe" -ForegroundColor DarkGray
    Write-Host "    BASH_ENV         = $bashrcFile" -ForegroundColor DarkGray
    Write-Host "    MSYS2_PATH_TYPE  = inherit" -ForegroundColor DarkGray
}

# ─────────────────────────────────────────────
# 步骤 4：创建 ~/.bashrc
# ─────────────────────────────────────────────

function New-Bashrc {
    Write-Step "创建 ~/.bashrc"

    $bashrcFile = Join-Path $env:USERPROFILE ".bashrc"

    if (Test-Path $bashrcFile) {
        Write-Skipped "~/.bashrc 已存在，保留原文件"
        return
    }

    @"
# MSYS2_PATH_TYPE=inherit 已在 Claude Code settings.json 中配置，自动继承 Windows PATH
# 此文件通过 BASH_ENV 在每个非交互式 bash 进程中自动加载
"@ | Set-Content $bashrcFile -Encoding UTF8

    Write-Success "~/.bashrc 已创建：$bashrcFile"
}

# ─────────────────────────────────────────────
# 步骤 5：输出摘要
# ─────────────────────────────────────────────

function Write-Summary {
    $bashExe = Join-Path $Msys2Path "usr\bin\bash.exe"

    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  配置完成！" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

    Write-Host "`n后续步骤：" -ForegroundColor White

    Write-Host "  1. 重启 Claude Code 使配置生效" -ForegroundColor White

    $veriblePath = "C:\tools\verible"
    if (-not (Test-Path $veriblePath)) {
        Write-Host "  2. 手动安装 Verible（LSP 支持）：" -ForegroundColor White
        Write-Host "     https://github.com/chipsalliance/verible/releases" -ForegroundColor DarkGray
        Write-Host "     解压后将 bin 目录（或解压根目录）加入系统 PATH" -ForegroundColor DarkGray
    } else {
        Write-Success "Verible 已安装：$veriblePath"
    }

    Write-Host "  3. 在 Claude Code 中安装插件：" -ForegroundColor White
    Write-Host "     /plugin marketplace add xuesongjun/claude-plugins" -ForegroundColor DarkGray
    Write-Host "     /plugin install systemverilog-lsp@xsj-plugins" -ForegroundColor DarkGray

    Write-Host ""
}

# ─────────────────────────────────────────────
# 主流程
# ─────────────────────────────────────────────

try {
    Write-Host "`nClaude Code Windows 开发环境配置脚本" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

    Install-Msys2
    Install-Msys2Packages
    Set-ClaudeConfig
    New-Bashrc
    Write-Summary
}
catch {
    Write-Host "`n✗ 错误：$_" -ForegroundColor Red
    Write-Host "  请检查上方输出，解决问题后重新运行脚本" -ForegroundColor Yellow
    exit 1
}
