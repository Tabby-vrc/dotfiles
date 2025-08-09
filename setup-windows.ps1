#Requires -Version 7.0
<#
.SYNOPSIS
    Windows環境用dotfilesセットアップスクリプト
.DESCRIPTION
    Linux/WSL環境と共通のdotfiles設定をWindows環境にセットアップします。
    PowerShell 7以降が必要です。
#>

param(
    [switch]$DryRun,  # 実際の変更を行わず、実行予定の操作のみ表示
    [switch]$Force    # 既存ファイルを上書き
)

# エラー時にスクリプトを停止
$ErrorActionPreference = "Stop"

Write-Host "Windows環境用dotfilesセットアップ開始" -ForegroundColor Green

# 現在のディレクトリがdotfilesリポジトリかチェック
if (-not (Test-Path ".git") -or -not (Test-Path "starship.toml")) {
    Write-Error "dotfilesリポジトリのルートディレクトリで実行してください"
}

$DotfilesPath = $PWD.Path
Write-Host "Dotfilesパス: $DotfilesPath" -ForegroundColor Cyan

# Windows固有のパス設定
$Paths = @{
    Starship = "$env:USERPROFILE\.config\starship.toml"
    PowerShellProfile = "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
    NvimConfig = "$env:LOCALAPPDATA\nvim"
    LazyGitConfig = "$env:APPDATA\lazygit"
}

# 必要なディレクトリを作成
function New-RequiredDirectories {
    $Directories = @(
        "$env:USERPROFILE\.config"
        "$(Split-Path $Paths.PowerShellProfile)"
        "$(Split-Path $Paths.NvimConfig)"
        "$(Split-Path $Paths.LazyGitConfig)"
    )
    
    foreach ($Dir in $Directories) {
        if (-not (Test-Path $Dir)) {
            if ($DryRun) {
                Write-Host "[DRY RUN] ディレクトリ作成: $Dir" -ForegroundColor Yellow
            } else {
                New-Item -ItemType Directory -Path $Dir -Force | Out-Null
                Write-Host "ディレクトリ作成: $Dir" -ForegroundColor Green
            }
        }
    }
}

# シンボリックリンクまたはファイルコピーを作成
function Set-ConfigFile {
    param(
        [string]$Source,
        [string]$Target,
        [string]$Description
    )
    
    if (-not (Test-Path $Source)) {
        Write-Warning "ソースファイルが見つかりません: $Source"
        return
    }
    
    if (Test-Path $Target) {
        # スマートチェック: 既存の設定が正しいかどうかを確認
        $needsUpdate = $false
        $currentType = "不明"
        
        try {
            $item = Get-Item $Target -Force
            
            if ($item.LinkType -eq "SymbolicLink") {
                $currentType = "シンボリックリンク"
                $currentTarget = $item.Target
                
                # 相対パスを絶対パスに変換して比較
                $resolvedTarget = if ([System.IO.Path]::IsPathRooted($currentTarget)) { 
                    $currentTarget 
                } else { 
                    [System.IO.Path]::GetFullPath((Join-Path (Split-Path $Target) $currentTarget))
                }
                $resolvedSource = [System.IO.Path]::GetFullPath($Source)
                
                if ($resolvedTarget -eq $resolvedSource) {
                    Write-Host "✓ $Description は既に正しく設定されています ($currentType)" -ForegroundColor Green
                    return
                } else {
                    $needsUpdate = $true
                    Write-Host "! $Description のリンク先が違います: $currentTarget -> $Source" -ForegroundColor Yellow
                }
            } elseif ($item.PSIsContainer) {
                $currentType = "ディレクトリ"
                $needsUpdate = $true
            } else {
                $currentType = "ファイル"
                $needsUpdate = $true
            }
        } catch {
            $needsUpdate = $true
            Write-Host "! $Description の確認中にエラー: $_" -ForegroundColor Yellow
        }
        
        if ($needsUpdate) {
            if ($Force) {
                if ($DryRun) {
                    Write-Host "[DRY RUN] 既存の$currentType を削除: $Target" -ForegroundColor Yellow
                } else {
                    Remove-Item $Target -Force -Recurse
                    Write-Host "既存の$currentType を削除: $Target" -ForegroundColor Yellow
                }
            } else {
                Write-Warning "$Description は既に存在します ($currentType)。-Force オプションで上書きできます: $Target"
                return
            }
        }
    }
    
    try {
        if ($DryRun) {
            Write-Host "[DRY RUN] $Description セットアップ: $Source -> $Target" -ForegroundColor Yellow
        } else {
            # 開発者モードが有効でない場合はコピー、有効な場合はシンボリックリンク
            try {
                New-Item -ItemType SymbolicLink -Path $Target -Value $Source -Force | Out-Null
                Write-Host "$Description シンボリックリンク作成: $Target" -ForegroundColor Green
            } catch {
                # シンボリックリンクが作成できない場合はコピー
                if (Test-Path $Source -PathType Container) {
                    Copy-Item $Source $Target -Recurse -Force
                } else {
                    Copy-Item $Source $Target -Force
                }
                Write-Host "$Description ファイルコピー: $Target" -ForegroundColor Cyan
                Write-Host "  注意: 開発者モードを有効にするとシンボリックリンクが使用できます" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Error "$Description のセットアップに失敗: $_"
    }
}


# メイン実行
Write-Host "`n=== 必要なディレクトリを作成 ===" -ForegroundColor Magenta
New-RequiredDirectories

Write-Host "`n=== Starship設定 ===" -ForegroundColor Magenta
Set-ConfigFile -Source "$DotfilesPath\starship.toml" -Target $Paths.Starship -Description "Starship設定"

Write-Host "`n=== LazyGit設定 ===" -ForegroundColor Magenta
Set-ConfigFile -Source "$DotfilesPath\lazygit" -Target $Paths.LazyGitConfig -Description "LazyGit設定"

Write-Host "`n=== Neovim設定 ===" -ForegroundColor Magenta
Set-ConfigFile -Source "$DotfilesPath\nvim" -Target $Paths.NvimConfig -Description "Neovim設定"

Write-Host "`n=== PowerShell設定 ===" -ForegroundColor Magenta
Set-ConfigFile -Source "$DotfilesPath\Microsoft.PowerShell_profile.ps1" -Target $Paths.PowerShellProfile -Description "PowerShell設定"

Write-Host "`n=== セットアップ完了 ===" -ForegroundColor Green

if (-not $DryRun) {
    Write-Host "次の手順:" -ForegroundColor Cyan
    Write-Host "1. PowerShellを再起動"
    Write-Host "2. 必要なツールをインストール: winget install starship lazygit neovim"
    Write-Host "3. フォントをインストール (Nerd Font推奨)"
    Write-Host "4. Windows Terminalの設定を調整"
}