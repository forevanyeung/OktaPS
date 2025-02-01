# Example output:
# Name                           Value
# ----                           -----
# OktaAdminDomain                https://clearme-admin.okta.com
# OktaAuthorizationMode          AuthorizationCode
# OktaDomain                     https://clearme.okta.com
# OktaOAuthClientId              0oal870p8yln0so89297
# OktaOAuthRefreshToken          
# OktaOAuthToken                 System.Security.SecureString
# OktaOrg                        clearme
# OktaSSO                        Microsoft.PowerShell.Commands.WebRequestSession
# OktaSSOExpirationUTC           2/1/2025 6:25:42 AM
Function Get-OktaPrivateVariables {
    Get-Variable -Name "Okta*" -Scope Script
}
