# Example output:
# Name                           Value
# ----                           -----
# OktaAdminDomain                https://dev-8675309-admin.okta.com
# OktaAuthorizationMode          AuthorizationCode
# OktaDomain                     https://dev-8675309.okta.com
# OktaOAuthClientId              0oal870p8yln0so89297
# OktaOAuthRefreshToken          System.Security.SecureString
# OktaOAuthToken                 System.Security.SecureString
# OktaOrg                        dev-8675309
# OktaSSO                        Microsoft.PowerShell.Commands.WebRequestSession
# OktaSSOExpirationUTC           2/1/2025 6:25:42 AM
Function Get-OktaPrivateVariables {
    Get-Variable -Name "Okta*" -Scope Script
}
