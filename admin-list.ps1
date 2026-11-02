# List usernames and server-side account/AI status. Requires the admin secret.
$ErrorActionPreference = 'Stop'
$ApiBase = Read-Host 'Enter your Cloudflare Worker URL (https://....workers.dev)'
$AdminSecret = Read-Host 'Enter ADMIN_PROVISIONING_SECRET' -AsSecureString
$BSTR = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminSecret)
try { $SecretPlain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR) }
try { Invoke-RestMethod -Method Get -Uri "$ApiBase/admin/list" -Headers @{ 'x-foodsafe-admin-secret' = $SecretPlain } | ConvertTo-Json -Depth 5 }
finally { $SecretPlain = $null }
