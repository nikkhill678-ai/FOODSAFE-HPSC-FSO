# Run locally in PowerShell. The admin secret and learner password are prompted, not stored in this file.
$ErrorActionPreference = 'Stop'
$ApiBase = Read-Host 'Enter your Cloudflare Worker URL (https://....workers.dev)'
$AdminSecret = Read-Host 'Enter ADMIN_PROVISIONING_SECRET' -AsSecureString
$BSTR = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminSecret)
try { $SecretPlain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR) }
$Username = (Read-Host 'Learner username (must match their FOODSAFE username)').Trim().ToLower()
$Password = Read-Host 'Set learner password (minimum 12 characters)' -AsSecureString
$PB = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
try { $PasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($PB) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($PB) }
if ($PasswordPlain.Length -lt 12) { throw 'Password must contain at least 12 characters.' }
$Body = @{ username = $Username; password = $PasswordPlain } | ConvertTo-Json -Compress
try {
  Invoke-RestMethod -Method Post -Uri "$ApiBase/admin/provision" -Headers @{ 'x-foodsafe-admin-secret' = $SecretPlain } -ContentType 'application/json' -Body $Body | ConvertTo-Json
} finally { $PasswordPlain = $null; $SecretPlain = $null; $Body = $null }
