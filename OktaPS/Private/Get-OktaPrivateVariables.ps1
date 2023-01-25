Function Get-OktaPrivateVariables {
    Get-Variable -Name "Okta*" -Scope Script
}