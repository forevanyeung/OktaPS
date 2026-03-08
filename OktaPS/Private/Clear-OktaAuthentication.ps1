Function Clear-OktaAuthentication {
    Stop-OktaSessionRefreshTimer
    $Script:OktaAuth = [hashtable]::Synchronized(@{})
}
