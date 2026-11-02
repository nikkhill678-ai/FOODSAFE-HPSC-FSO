# Grant Gemini to an existing FOODSAFE account without changing its password.
$ErrorActionPreference = 'Stop'
$ApiBase = Read-Host 'Enter your Cloudflare Worker URL (https://....workers.dev)'
$AdminSecret = Read-Host 'Enter ADMIN_PROVISIONING_SECRET' -AsSecureString
$BSTR = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminSecret)
try { $SecretPlain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR) }
$Username = (Read-Host 'Existing FOODSAFE username to grant Gemini').Trim().ToLower()
try { Invoke-RestMethod -Method Post -Uri "$ApiBase/admin/ai-enable" -Headers @{ 'x-foodsafe-admin-secret' = $SecretPlain } -ContentType 'application/json' -Body (@{username=$Username}|ConvertTo-Json -Compress) | ConvertTo-Json }
finally { $SecretPlain = $null }
