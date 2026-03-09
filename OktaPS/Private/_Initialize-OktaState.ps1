$Script:OktaAuth    = [hashtable]::Synchronized(@{})
$Script:OktaSetting = [hashtable]::Synchronized(@{
    SuppressAdminAPIWarning  = $false
    UserAgentString          = $null
    RefreshTimerExperimental = $false
})
