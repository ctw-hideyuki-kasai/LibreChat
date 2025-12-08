# AWS Infrastructure Setup Script for LibreChat
# PowerShell script for AWS EC2 deployment

Write-Host "=== LibreChat AWS Infrastructure Setup ===" -ForegroundColor Green

# 設定変数
$INSTANCE_TYPE = "t3.medium"
$AMI_ID = "ami-0d52744d6551d851e"  # Ubuntu 20.04 LTS (ap-northeast-1)
$KEY_PAIR_NAME = "librechat-key-pair"
$SECURITY_GROUP_NAME = "librechat-sg"
$REGION = "ap-northeast-1"

Write-Host "`n=== Step 1: AWS 接続確認 ===" -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity --output json | ConvertFrom-Json
    Write-Host "✓ AWS認証成功" -ForegroundColor Green
    Write-Host "  アカウントID: $($identity.Account)" -ForegroundColor Cyan
    Write-Host "  ユーザー: $($identity.Arn)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ AWS認証失敗。aws configure を再実行してください" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Step 2: Bedrock 利用可能性確認 ===" -ForegroundColor Yellow
try {
    $bedrockModels = aws bedrock list-foundation-models --region us-east-1 --output json 2>$null | ConvertFrom-Json
    $claudeModels = $bedrockModels.modelSummaries | Where-Object { $_.modelName -like "*claude*" }
    if ($claudeModels.Count -gt 0) {
        Write-Host "✓ Bedrock Claude モデル利用可能 ($($claudeModels.Count)個)" -ForegroundColor Green
        foreach ($model in $claudeModels) {
            Write-Host "  - $($model.modelId)" -ForegroundColor Cyan
        }
    } else {
        Write-Host "⚠ Bedrock Claude モデルが見つかりません" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠ Bedrock アクセス確認でエラー。後でIAM権限を確認してください" -ForegroundColor Yellow
}

Write-Host "`n=== Step 3: キーペア作成 ===" -ForegroundColor Yellow
try {
    # 既存のキーペア確認
    $existingKeyPair = aws ec2 describe-key-pairs --key-names $KEY_PAIR_NAME --region $REGION 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ キーペア '$KEY_PAIR_NAME' は既に存在します" -ForegroundColor Green
    } else {
        # キーペア作成
        $keyPairOutput = aws ec2 create-key-pair --key-name $KEY_PAIR_NAME --region $REGION --output json | ConvertFrom-Json
        $privateKey = $keyPairOutput.KeyMaterial
        
        # 秘密鍵をファイルに保存
        $keyPath = "$PWD\$KEY_PAIR_NAME.pem"
        $privateKey | Out-File -FilePath $keyPath -Encoding ASCII
        
        Write-Host "✓ キーペア '$KEY_PAIR_NAME' を作成しました" -ForegroundColor Green
        Write-Host "  秘密鍵: $keyPath" -ForegroundColor Cyan
        Write-Host "  ⚠ この秘密鍵ファイルは安全に保管してください" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ キーペア作成でエラーが発生しました" -ForegroundColor Red
}

Write-Host "`n=== Step 4: セキュリティグループ作成 ===" -ForegroundColor Yellow
try {
    # 既存のセキュリティグループ確認
    $existingSG = aws ec2 describe-security-groups --group-names $SECURITY_GROUP_NAME --region $REGION 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ セキュリティグループ '$SECURITY_GROUP_NAME' は既に存在します" -ForegroundColor Green
        $sgInfo = $existingSG | ConvertFrom-Json
        $sgId = $sgInfo.SecurityGroups[0].GroupId
    } else {
        # セキュリティグループ作成
        $sgOutput = aws ec2 create-security-group --group-name $SECURITY_GROUP_NAME --description "Security group for LibreChat" --region $REGION --output json | ConvertFrom-Json
        $sgId = $sgOutput.GroupId
        Write-Host "✓ セキュリティグループ '$SECURITY_GROUP_NAME' を作成しました (ID: $sgId)" -ForegroundColor Green
        
        # セキュリティグループルール追加
        Write-Host "  セキュリティグループルールを追加中..." -ForegroundColor Cyan
        
        # SSH (22)
        aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $REGION
        Write-Host "    ✓ SSH (22) ルール追加" -ForegroundColor Green
        
        # HTTP (80)
        aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $REGION
        Write-Host "    ✓ HTTP (80) ルール追加" -ForegroundColor Green
        
        # HTTPS (443)
        aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 443 --cidr 0.0.0.0/0 --region $REGION
        Write-Host "    ✓ HTTPS (443) ルール追加" -ForegroundColor Green
        
        # LibreChat (3080)
        aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 3080 --cidr 0.0.0.0/0 --region $REGION
        Write-Host "    ✓ LibreChat (3080) ルール追加" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ セキュリティグループ作成でエラーが発生しました" -ForegroundColor Red
}

Write-Host "`n=== Step 5: EC2インスタンス作成 ===" -ForegroundColor Yellow
$createInstance = Read-Host "EC2インスタンスを作成しますか？ (y/n)"
if ($createInstance -eq "y" -or $createInstance -eq "Y") {
    try {
        # インスタンス作成
        Write-Host "  EC2インスタンスを作成中..." -ForegroundColor Cyan
        $instanceOutput = aws ec2 run-instances `
            --image-id $AMI_ID `
            --count 1 `
            --instance-type $INSTANCE_TYPE `
            --key-name $KEY_PAIR_NAME `
            --security-groups $SECURITY_GROUP_NAME `
            --region $REGION `
            --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=LibreChat-Server}]' `
            --output json | ConvertFrom-Json
            
        $instanceId = $instanceOutput.Instances[0].InstanceId
        Write-Host "✓ EC2インスタンス作成成功" -ForegroundColor Green
        Write-Host "  インスタンスID: $instanceId" -ForegroundColor Cyan
        Write-Host "  インスタンスタイプ: $INSTANCE_TYPE" -ForegroundColor Cyan
        
        # インスタンス起動待機
        Write-Host "  インスタンス起動を待機中..." -ForegroundColor Cyan
        aws ec2 wait instance-running --instance-ids $instanceId --region $REGION
        Write-Host "✓ インスタンス起動完了" -ForegroundColor Green
        
        # インスタンス情報取得
        $instanceInfo = aws ec2 describe-instances --instance-ids $instanceId --region $REGION --output json | ConvertFrom-Json
        $publicIp = $instanceInfo.Reservations[0].Instances[0].PublicIpAddress
        $privateIp = $instanceInfo.Reservations[0].Instances[0].PrivateIpAddress
        
        Write-Host "  パブリックIP: $publicIp" -ForegroundColor Cyan
        Write-Host "  プライベートIP: $privateIp" -ForegroundColor Cyan
        
    } catch {
        Write-Host "✗ EC2インスタンス作成でエラーが発生しました" -ForegroundColor Red
    }
} else {
    Write-Host "  EC2インスタンス作成をスキップしました" -ForegroundColor Yellow
}

Write-Host "`n=== Step 6: Elastic IP作成・割り当て ===" -ForegroundColor Yellow
if ($instanceId -and ($createInstance -eq "y" -or $createInstance -eq "Y")) {
    $createEIP = Read-Host "Elastic IPを作成・割り当てしますか？ (y/n)"
    if ($createEIP -eq "y" -or $createEIP -eq "Y") {
        try {
            # Elastic IP作成
            $eipOutput = aws ec2 allocate-address --domain vpc --region $REGION --output json | ConvertFrom-Json
            $elasticIp = $eipOutput.PublicIp
            $allocationId = $eipOutput.AllocationId
            Write-Host "✓ Elastic IP作成成功: $elasticIp" -ForegroundColor Green
            
            # インスタンスに割り当て
            aws ec2 associate-address --instance-id $instanceId --allocation-id $allocationId --region $REGION
            Write-Host "✓ Elastic IPをインスタンスに割り当て完了" -ForegroundColor Green
            Write-Host "  固定IP: $elasticIp" -ForegroundColor Cyan
            
        } catch {
            Write-Host "✗ Elastic IP作成・割り当てでエラーが発生しました" -ForegroundColor Red
        }
    }
}

Write-Host "`n=== Step 7: IAMポリシー・ロール作成 (Bedrock用) ===" -ForegroundColor Yellow
$createIAM = Read-Host "Bedrock用IAMポリシーを作成しますか？ (y/n)"
if ($createIAM -eq "y" -or $createIAM -eq "Y") {
    try {
        # Bedrockポリシー作成
        $policyDocument = @{
            Version = "2012-10-17"
            Statement = @(
                @{
                    Effect = "Allow"
                    Action = @(
                        "bedrock:InvokeModel",
                        "bedrock:InvokeModelWithResponseStream", 
                        "bedrock:ListFoundationModels"
                    )
                    Resource = "*"
                }
            )
        } | ConvertTo-Json -Depth 3
        
        $policyName = "LibreChatBedrockPolicy"
        
        # ポリシー作成
        $policyOutput = aws iam create-policy --policy-name $policyName --policy-document $policyDocument --description "Policy for LibreChat Bedrock access" --output json 2>$null | ConvertFrom-Json
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ IAMポリシー '$policyName' を作成しました" -ForegroundColor Green
            Write-Host "  ポリシーARN: $($policyOutput.Policy.Arn)" -ForegroundColor Cyan
            Write-Host "  ※ このポリシーをIAMユーザーにアタッチしてください" -ForegroundColor Yellow
        } else {
            Write-Host "⚠ IAMポリシーは既に存在するか、作成できませんでした" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "✗ IAMポリシー作成でエラーが発生しました" -ForegroundColor Red
    }
}

Write-Host "`n=== セットアップ完了 ===" -ForegroundColor Green
Write-Host "`n作成されたリソース:" -ForegroundColor Cyan
Write-Host "- キーペア: $KEY_PAIR_NAME" -ForegroundColor White
Write-Host "- セキュリティグループ: $SECURITY_GROUP_NAME" -ForegroundColor White
if ($instanceId) {
    Write-Host "- EC2インスタンス: $instanceId" -ForegroundColor White
    Write-Host "- パブリックIP: $publicIp" -ForegroundColor White
}
if ($elasticIp) {
    Write-Host "- Elastic IP: $elasticIp" -ForegroundColor White
}

Write-Host "`n次のステップ:" -ForegroundColor Yellow
Write-Host "1. Route53でドメインのAレコードを更新 (Elastic IP宛て)"
Write-Host "2. EC2インスタンスにSSH接続"
Write-Host "3. Docker, Docker Compose, Gitのインストール"
Write-Host "4. LibreChatのデプロイ"

if ($instanceId -and $elasticIp) {
    Write-Host "`nSSH接続コマンド:" -ForegroundColor Cyan
    Write-Host "ssh -i $KEY_PAIR_NAME.pem ubuntu@$elasticIp" -ForegroundColor White
}

Read-Host "`nEnterキーを押して終了"