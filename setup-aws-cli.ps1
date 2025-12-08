# AWS CLI セットアップスクリプト (PowerShell)
# LibreChat AWS Deployment用

Write-Host "=== AWS CLI セットアップスクリプト ===" -ForegroundColor Green

# AWS CLIがインストール済みかチェック
Write-Host "`n1. AWS CLI インストール状況確認..." -ForegroundColor Yellow
try {
    $awsVersion = aws --version 2>&1
    Write-Host "AWS CLI インストール済み: $awsVersion" -ForegroundColor Green
    $awsInstalled = $true
} catch {
    Write-Host "AWS CLI がインストールされていません" -ForegroundColor Red
    $awsInstalled = $false
}

# AWS CLIインストール (必要に応じて)
if (-not $awsInstalled) {
    Write-Host "`n2. AWS CLI インストール..." -ForegroundColor Yellow
    Write-Host "以下の方法でAWS CLIをインストールしてください:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "オプション1: Windows Installer (推奨)" -ForegroundColor White
    Write-Host "https://awscli.amazonaws.com/AWSCLIV2.msi からダウンロード・インストール"
    Write-Host ""
    Write-Host "オプション2: pip経由でインストール" -ForegroundColor White
    Write-Host "pip install awscli"
    Write-Host ""
    Write-Host "オプション3: Chocolateyでインストール" -ForegroundColor White
    Write-Host "choco install awscli"
    Write-Host ""
    Write-Host "インストール後、PowerShellを再起動してこのスクリプトを再実行してください。" -ForegroundColor Yellow
    Read-Host "Enterキーを押して終了"
    exit
}

# AWS設定状況確認
Write-Host "`n3. AWS設定状況確認..." -ForegroundColor Yellow
try {
    $awsConfig = aws configure list 2>&1
    Write-Host "現在のAWS設定:" -ForegroundColor Green
    Write-Host $awsConfig
    
    # 設定済みかチェック
    if ($awsConfig -match "access_key.*<not set>") {
        Write-Host "`nAWS認証情報が設定されていません" -ForegroundColor Red
        $needsConfig = $true
    } else {
        Write-Host "`nAWS認証情報設定済み" -ForegroundColor Green
        $needsConfig = $false
    }
} catch {
    Write-Host "AWS設定確認でエラーが発生しました" -ForegroundColor Red
    $needsConfig = $true
}

# AWS認証情報設定
if ($needsConfig) {
    Write-Host "`n4. AWS認証情報設定..." -ForegroundColor Yellow
    Write-Host "以下のコマンドでAWS認証情報を設定してください:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "aws configure" -ForegroundColor White
    Write-Host ""
    Write-Host "設定が必要な項目:" -ForegroundColor Cyan
    Write-Host "- AWS Access Key ID: (IAMユーザーのアクセスキー)"
    Write-Host "- AWS Secret Access Key: (IAMユーザーのシークレットキー)"
    Write-Host "- Default region name: ap-northeast-1 (東京リージョン)"
    Write-Host "- Default output format: json"
    Write-Host ""
    
    $configNow = Read-Host "今すぐ設定しますか？ (y/n)"
    if ($configNow -eq "y" -or $configNow -eq "Y") {
        aws configure
    } else {
        Write-Host "後で 'aws configure' コマンドで設定してください" -ForegroundColor Yellow
    }
}

# 接続テスト
Write-Host "`n5. AWS接続テスト..." -ForegroundColor Yellow
try {
    Write-Host "AWS STS (Security Token Service) テスト中..."
    $stsResult = aws sts get-caller-identity 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "AWS接続成功!" -ForegroundColor Green
        Write-Host $stsResult
        
        # Bedrock利用可能リージョン確認
        Write-Host "`n6. Bedrock利用可能リージョン確認..." -ForegroundColor Yellow
        $regions = @("us-east-1", "us-west-2", "ap-northeast-1")
        foreach ($region in $regions) {
            Write-Host "リージョン $region でBedrock確認中..." -ForegroundColor Cyan
            try {
                $bedrockModels = aws bedrock list-foundation-models --region $region 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $modelCount = ($bedrockModels | ConvertFrom-Json).modelSummaries.Count
                    Write-Host "  ✓ $region : $modelCount 個のモデルが利用可能" -ForegroundColor Green
                } else {
                    Write-Host "  ✗ $region : アクセス不可 - $bedrockModels" -ForegroundColor Red
                }
            } catch {
                Write-Host "  ✗ $region : エラー発生" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "AWS接続失敗: $stsResult" -ForegroundColor Red
        Write-Host "認証情報を確認してください" -ForegroundColor Yellow
    }
} catch {
    Write-Host "接続テストでエラーが発生しました" -ForegroundColor Red
}

# EC2インスタンス一覧確認
Write-Host "`n7. EC2インスタンス確認..." -ForegroundColor Yellow
try {
    $ec2Instances = aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType,PublicIpAddress]' --output table 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "EC2インスタンス一覧:" -ForegroundColor Green
        Write-Host $ec2Instances
    } else {
        Write-Host "EC2インスタンス取得失敗: $ec2Instances" -ForegroundColor Red
    }
} catch {
    Write-Host "EC2情報取得でエラーが発生しました" -ForegroundColor Red
}

# 必要なツールチェック
Write-Host "`n8. 必要なツール確認..." -ForegroundColor Yellow

# Git確認
try {
    $gitVersion = git --version 2>&1
    Write-Host "Git: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "Git がインストールされていません - https://git-scm.com/ からインストール" -ForegroundColor Red
}

# Node.js確認
try {
    $nodeVersion = node --version 2>&1
    Write-Host "Node.js: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "Node.js がインストールされていません - https://nodejs.org/ からインストール" -ForegroundColor Red
}

# Docker確認
try {
    $dockerVersion = docker --version 2>&1
    Write-Host "Docker: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "Docker がインストールされていません - https://www.docker.com/products/docker-desktop からインストール" -ForegroundColor Red
}

Write-Host "`n=== セットアップ完了 ===" -ForegroundColor Green
Write-Host "次のステップ:" -ForegroundColor Cyan
Write-Host "1. EC2インスタンスの作成・設定"
Write-Host "2. Elastic IPの取得・設定"
Write-Host "3. セキュリティグループの設定"
Write-Host "4. IAMユーザーの作成・権限設定"

Read-Host "`nEnterキーを押して終了"