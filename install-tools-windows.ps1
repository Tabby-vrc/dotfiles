#Requires -Version 7.0
<#
.SYNOPSIS
    Windows環境用開発ツール一括インストールスクリプト
.DESCRIPTION
    dotfiles環境で使用する開発ツールをwingetを使って安全にインストールします。
    既にインストール済みのツールはスキップされ、何度実行しても安全です。
.PARAMETER DryRun
    実際のインストールを行わず、実行予定の操作のみ表示
.PARAMETER UpdateAll
    既にインストール済みのツールも最新版に更新
.PARAMETER SkipOptional
    オプションツールのインストールをスキップ
#>

param(
    [switch]$DryRun,
    [switch]$UpdateAll,
    [switch]$SkipOptional
)

# エラー時にスクリプトを停止
$ErrorActionPreference = "Stop"

Write-Host "Windows環境用開発ツールインストール開始" -ForegroundColor Green
Write-Host "winget バージョン: $(winget --version)" -ForegroundColor Cyan

# インストール対象ツールの定義
$CoreTools = @(
    @{
        Name = "Git"
        WingetId = "Git.Git"
        Command = "git"
        Description = "バージョン管理システム"
        Required = $true
    },
    @{
        Name = "PowerShell 7"
        WingetId = "Microsoft.PowerShell"
        Command = "pwsh"
        Description = "モダンなPowerShell"
        Required = $true
    },
    @{
        Name = "Starship"
        WingetId = "Starship.Starship"
        Command = "starship"
        Description = "クロスシェル対応プロンプト"
        Required = $true
    },
    @{
        Name = "LazyGit"
        WingetId = "JesseDuffield.Lazygit"
        Command = "lazygit"
        Description = "Git用TUIツール"
        Required = $true
    },
    @{
        Name = "Neovim"
        WingetId = "Neovim.Neovim"
        Command = "nvim"
        Description = "モダンなVimエディタ"
        Required = $true
    },
    @{
        Name = "zoxide"
        WingetId = "ajeetdsouza.zoxide"
        Command = "zoxide"
        Description = "スマートなディレクトリジャンプ"
        Required = $true
    }
)

$OptionalTools = @(
    @{
        Name = "Windows Terminal"
        WingetId = "Microsoft.WindowsTerminal"
        Command = "wt"
        Description = "モダンなターミナルアプリ"
        Required = $false
    },
    @{
        Name = "fzf"
        WingetId = "junegunn.fzf"
        Command = "fzf"
        Description = "コマンドライン用ファジー検索"
        Required = $false
    },
    @{
        Name = "ripgrep"
        WingetId = "BurntSushi.ripgrep.MSVC"
        Command = "rg"
        Description = "高速なgrep代替ツール"
        Required = $false
    },
    @{
        Name = "lsd"
        WingetId = "lsd-rs.lsd"
        Command = "lsd"
        Description = "モダンなls代替ツール"
        Required = $false
    },
    @{
        Name = "ghq"
        WingetId = "x-motemen.ghq"
        Command = "ghq"
        Description = "Gitリポジトリ管理ツール"
        Required = $false
    }
)

# ツールがインストールされているかチェック
function Test-ToolInstalled {
    param([string]$Command)
    
    try {
        $null = Get-Command $Command -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# wingetでツールをインストール
function Install-Tool {
    param(
        [hashtable]$Tool,
        [switch]$Force = $false
    )
    
    $isInstalled = Test-ToolInstalled -Command $Tool.Command
    
    if ($isInstalled -and -not $Force) {
        Write-Host "✓ $($Tool.Name) は既にインストール済みです" -ForegroundColor Green
        return $true
    }
    
    $action = if ($isInstalled) { "更新" } else { "インストール" }
    
    if ($DryRun) {
        Write-Host "[DRY RUN] $($Tool.Name) を$action します (winget install $($Tool.WingetId))" -ForegroundColor Yellow
        return $true
    }
    
    try {
        Write-Host "$($Tool.Name) を$action 中..." -ForegroundColor Cyan
        
        $installArgs = @("install", $Tool.WingetId, "--exact", "--accept-package-agreements", "--accept-source-agreements")
        if ($Force) {
            $installArgs += "--force"
        }
        
        $result = & winget @installArgs 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ $($Tool.Name) の$action が完了しました" -ForegroundColor Green
            return $true
        } else {
            Write-Warning "$($Tool.Name) の$action に失敗しました: $result"
            return $false
        }
    } catch {
        Write-Warning "$($Tool.Name) の$action 中にエラーが発生しました: $_"
        return $false
    }
}

# インストール状況の表示
function Show-InstallationStatus {
    param([array]$Tools, [string]$Category)
    
    Write-Host "`n=== $Category ===" -ForegroundColor Magenta
    
    foreach ($tool in $Tools) {
        $isInstalled = Test-ToolInstalled -Command $tool.Command
        $status = if ($isInstalled) { "✓" } else { "✗" }
        $color = if ($isInstalled) { "Green" } else { "Red" }
        
        Write-Host "$status $($tool.Name) - $($tool.Description)" -ForegroundColor $color
    }
}

# PATH更新の通知
function Show-PathUpdateNotice {
    Write-Host "`n=== 重要な注意事項 ===" -ForegroundColor Yellow
    Write-Host "新しくインストールされたツールを使用するには、以下のいずれかを実行してください:" -ForegroundColor Yellow
    Write-Host "1. PowerShellを再起動する" -ForegroundColor Cyan
    Write-Host "2. 環境変数を再読み込みする: " -NoNewline -ForegroundColor Cyan
    Write-Host 'refreshenv' -ForegroundColor White
    Write-Host "3. 新しいPowerShellセッションを開始する" -ForegroundColor Cyan
}

# フォント推奨の表示
function Show-FontRecommendation {
    Write-Host "`n=== フォント推奨 ===" -ForegroundColor Magenta
    Write-Host "Starshipとnvimでアイコンを正しく表示するため、Nerd Fontの使用を推奨します:" -ForegroundColor Yellow
    Write-Host "• 推奨フォント: HackGen Console NF, JetBrains Mono Nerd Font" -ForegroundColor Cyan
    Write-Host "• インストール方法: https://www.nerdfonts.com/ からダウンロード" -ForegroundColor Cyan
    Write-Host "• Windows Terminal設定で使用フォントを変更してください" -ForegroundColor Cyan
}

# メイン処理
Write-Host "`n=== インストール状況確認 ===" -ForegroundColor Magenta
Show-InstallationStatus -Tools $CoreTools -Category "必須ツール"
if (-not $SkipOptional) {
    Show-InstallationStatus -Tools $OptionalTools -Category "オプションツール"
}

if ($DryRun) {
    Write-Host "`n[DRY RUN モード] 実際のインストールは実行されません" -ForegroundColor Yellow
}

# 必須ツールのインストール
Write-Host "`n=== 必須ツールのインストール ===" -ForegroundColor Magenta
$coreInstallCount = 0
foreach ($tool in $CoreTools) {
    if (Install-Tool -Tool $tool -Force:$UpdateAll) {
        $coreInstallCount++
    }
}

# オプションツールのインストール
if (-not $SkipOptional) {
    Write-Host "`n=== オプションツールのインストール ===" -ForegroundColor Magenta
    $optionalInstallCount = 0
    foreach ($tool in $OptionalTools) {
        if (Install-Tool -Tool $tool -Force:$UpdateAll) {
            $optionalInstallCount++
        }
    }
}

# 完了メッセージ
Write-Host "`n=== インストール完了 ===" -ForegroundColor Green

if (-not $DryRun) {
    Write-Host "必須ツール: $coreInstallCount/$($CoreTools.Count) 個処理完了" -ForegroundColor Cyan
    if (-not $SkipOptional) {
        Write-Host "オプションツール: $optionalInstallCount/$($OptionalTools.Count) 個処理完了" -ForegroundColor Cyan
    }
    
    Show-PathUpdateNotice
    Show-FontRecommendation
    
    Write-Host "`n次のステップ:" -ForegroundColor Cyan
    Write-Host "1. PowerShellを再起動" -ForegroundColor White
    Write-Host "2. dotfiles設定を適用: .\setup-windows.ps1" -ForegroundColor White
    Write-Host "3. 各ツールの動作確認: starship --version, lazygit --version など" -ForegroundColor White
}