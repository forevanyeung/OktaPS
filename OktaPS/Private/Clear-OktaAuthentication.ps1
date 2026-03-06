Function Clear-OktaAuthentication {
    Stop-OktaSessionRefreshTimer
    Remove-Variable -Scope Script -Name OktaAdminDomain -ErrorAction SilentlyContinue
    Remove-Variable -Scope Script -Name OktaAuthorizationMode -ErrorAction SilentlyContinue
    Remove-Variable -Scope Script -Name OktaDomain -ErrorAction SilentlyContinue
    Remove-Variable -Scope Script -Name OktaOrg -ErrorAction SilentlyContinue
    Remove-Variable -Scope Script -Name OktaSSO -ErrorAction SilentlyContinue
    Remove-Variable -Scope Script -Name OktaSSOExpirationUTC -ErrorAction SilentlyContinue
    Remove-Variable -Scope Script -Name OktaUsername -ErrorAction SilentlyContinue
    Remove-Variable -Scope Script -Name OktaXSRF -ErrorAction SilentlyContinue
}