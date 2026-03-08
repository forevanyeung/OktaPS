$Script:OktaAuth   = [hashtable]::Synchronized(@{})
$Script:OktaConfig = [hashtable]::Synchronized(@{
    SuppressAdminAPIWarning = $false
    UserAgentString         = $null
})
