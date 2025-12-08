# LibreChat Secrets Generation Script
# This script generates all required secrets for LibreChat deployment

Write-Host "=== LibreChat Secrets Generation ===" -ForegroundColor Green
Write-Host "Generating secure random secrets..." -ForegroundColor Cyan

# Function to generate random hex string
function Get-RandomHex {
    param([int]$Length)
    -join ((1..$Length) | ForEach {'{0:x}' -f (Get-Random -Max 16)})
}

# Function to generate random base64 string
function Get-RandomBase64 {
    param([int]$Length)
    $bytes = New-Object byte[] $Length
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    [Convert]::ToBase64String($bytes)
}

Write-Host "`n=== 生成中... ===" -ForegroundColor Yellow

# Generate JWT secrets (32 characters hex)
$JWT_SECRET = Get-RandomHex -Length 32
$JWT_REFRESH_SECRET = Get-RandomHex -Length 32

# Generate CREDS keys
$CREDS_KEY = Get-RandomHex -Length 32  # Exactly 32 characters
$CREDS_IV = Get-RandomHex -Length 16   # Exactly 16 characters

# Generate MEILI_MASTER_KEY (base64)
$MEILI_MASTER_KEY = Get-RandomBase64 -Length 32

# Generate PostgreSQL password (base64)
$POSTGRES_PASSWORD = Get-RandomBase64 -Length 16

Write-Host "✓ 全てのシークレットを生成しました" -ForegroundColor Green

# Display results
Write-Host "`n=== 生成されたシークレット ===" -ForegroundColor Yellow

Write-Host "`n[JWT関連]" -ForegroundColor Cyan
Write-Host "JWT_SECRET=$JWT_SECRET" -ForegroundColor White
Write-Host "JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET" -ForegroundColor White

Write-Host "`n[暗号化関連]" -ForegroundColor Cyan
Write-Host "CREDS_KEY=$CREDS_KEY" -ForegroundColor White
Write-Host "CREDS_IV=$CREDS_IV" -ForegroundColor White

Write-Host "`n[データベース]" -ForegroundColor Cyan
Write-Host "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" -ForegroundColor White

Write-Host "`n[検索エンジン]" -ForegroundColor Cyan
Write-Host "MEILI_MASTER_KEY=$MEILI_MASTER_KEY" -ForegroundColor White

# Create secrets record file
$secretsRecord = @"
# LibreChat Generated Secrets
# Generated on: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# ⚠️ CONFIDENTIAL - Do not share or commit to version control

## JWT Authentication
JWT_SECRET=$JWT_SECRET
JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET

## Encryption Keys
CREDS_KEY=$CREDS_KEY
CREDS_IV=$CREDS_IV

## Database
POSTGRES_PASSWORD=$POSTGRES_PASSWORD

## Search Engine
MEILI_MASTER_KEY=$MEILI_MASTER_KEY

## Validation
- JWT_SECRET length: $($JWT_SECRET.Length) characters ✓
- JWT_REFRESH_SECRET length: $($JWT_REFRESH_SECRET.Length) characters ✓
- CREDS_KEY length: $($CREDS_KEY.Length) characters ✓
- CREDS_IV length: $($CREDS_IV.Length) characters ✓
- POSTGRES_PASSWORD: Base64 encoded ✓
- MEILI_MASTER_KEY: Base64 encoded ✓
"@

# Save to file
$secretsFile = "generated-secrets.txt"
$secretsRecord | Out-File -FilePath $secretsFile -Encoding UTF8

Write-Host "`n✓ シークレットを保存しました: $secretsFile" -ForegroundColor Green
Write-Host "⚠️  このファイルは機密情報です。適切に管理してください。" -ForegroundColor Yellow

# Update SECRETS-TEMPLATE.md
if (Test-Path "SECRETS-TEMPLATE.md") {
    $templateContent = Get-Content "SECRETS-TEMPLATE.md" -Raw
    $updatedContent = $templateContent -replace "JWT_SECRET=", "JWT_SECRET=$JWT_SECRET"
    $updatedContent = $updatedContent -replace "JWT_REFRESH_SECRET=", "JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET"
    $updatedContent = $updatedContent -replace "CREDS_KEY=                    # 正確に32文字", "CREDS_KEY=$CREDS_KEY"
    $updatedContent = $updatedContent -replace "CREDS_IV=                     # 正確に16文字", "CREDS_IV=$CREDS_IV"
    $updatedContent = $updatedContent -replace "POSTGRES_PASSWORD=", "POSTGRES_PASSWORD=$POSTGRES_PASSWORD"
    $updatedContent = $updatedContent -replace "MEILI_MASTER_KEY=", "MEILI_MASTER_KEY=$MEILI_MASTER_KEY"
    
    $updatedContent | Out-File -FilePath "SECRETS-TEMPLATE-FILLED.md" -Encoding UTF8
    Write-Host "✓ SECRETS-TEMPLATE-FILLED.md を作成しました" -ForegroundColor Green
}

Write-Host "`n=== 次のステップ ===" -ForegroundColor Yellow
Write-Host "1. AWS認証情報を追加してください:"
Write-Host "   AWS_ACCESS_KEY_ID=your_access_key"
Write-Host "   AWS_SECRET_ACCESS_KEY=your_secret_key"
Write-Host ""
Write-Host "2. ドメイン情報を設定してください:"
Write-Host "   DOMAIN_CLIENT=https://your-domain.com"
Write-Host "   DOMAIN_SERVER=https://your-domain.com"
Write-Host ""
Write-Host "3. .env ファイルを作成してください"

Read-Host "`nEnterキーを押して終了"