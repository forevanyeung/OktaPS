Function Connect-OktaCredential {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]
        $OktaDomain,

        # Parameter help description
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    $okta_authn = Invoke-RestMethod -Uri "$OktaDomain/api/v1/authn" -Method "POST" -Body (@{
        "username" = $Credential.GetNetworkCredential().username
        "password" = $Credential.GetNetworkCredential().password
        "option" = @{
            "multiOptionalFactorEnroll" = "false"
            "warnBeforePasswordExpired" = "false"
        }
    } | ConvertTo-Json) -ContentType "application/json" -SessionVariable OktaSSO

    switch ($okta_authn.status) {
        SUCCESS { 
            $session_token = $okta_authn.sessionToken
        }

        MFA_REQUIRED {
            Write-Host "MFA is required"

            # if more than one mfa, prompt, or select the first one
            # https://developer.okta.com/docs/reference/api/factors/#supported-factors-for-providers
            $factorList = $okta_authn._embedded.factors
            If($factorList.count -gt 1) {
                $availableFactors = $factorList | ForEach-Object { $_.provider.ToLower() + "::" + $_.factorType }
                $chosenFactorIndex = Read-OktaFactorPrompt -AvailableFactors $availableFactors
            } else {
                $chosenFactorIndex = 0
            }
            $chosenFactor = $factorList[$chosenFactorIndex].provider.ToLower() + "::" + $factorList[$chosenFactorIndex].factorType
            switch ($chosenFactor) {
                "okta::push" {
                    $session_token = Send-OktaFactorProviderOkta -VerifyUrl $factorList[$chosenFactorIndex]._links.verify.href -StateToken $okta_authn.stateToken
                }

                "okta::token:software:totp" {
                    $totp = Read-Host "Enter code from Okta Verify app"
                    $session_token = Send-OktaFactorProviderOkta -VerifyUrl $factorList[$chosenFactorIndex]._links.verify.href -StateToken $okta_authn.stateToken -Passcode $totp
                }

                "duo::web" {
                    $session_token = Send-OktaFactorProviderDuo -VerifyUrl $factorList[$chosenFactorIndex]._links.verify.href -StateToken $okta_authn.stateToken
                }

                Default {
                    Write-Error "Unknown factor type: $factorType"
                    Return
                }
            }
        }

        Default {
            Write-Host "Authentication failed, unknown error."
            Return $okta.status
        }
    }

    # Trade session token for a session cookie
    $null = Invoke-WebRequest -Method "GET" -Uri "$OktaDomain/login/sessionCookieRedirect?token=$session_token&redirectUrl=$OktaDomain" -SkipHttpErrorCheck -WebSession $OktaSSO -MaximumRedirection 5
    $session = Invoke-RestMethod -Method "GET" -Uri "$OktaDomain/api/v1/sessions/me" -WebSession $OktaSSO

    # Get an XSRF Token
    # 
    $OktaAdminDomain = Get-OktaAdminDomain -Domain $OktaDomain
    $dashboard = Invoke-WebRequest -Method "GET" -Uri "$OktaAdminDomain/admin/dashboard" -WebSession $OktaSSO
    If($dashboard.content -match '(?:id="_xsrfToken".*?>)(?<xsrfToken>.*?)(?:<)') {
        If($Matches.xsrfToken.Length -gt 0) {
            $Script:OktaXSRF = $Matches.xsrfToken
        } else {
            Write-Warning "XSRF token length is 0. Some Okta endpoints might not be available."
        }
    } else {
        Write-Warning "Unable to get XSRF token. Some Okta endpoints might not be available."
    }

    Set-OktaAuthentication -AuthorizationMode "Credential" -Session $OktaSSO -Domain $OktaDomain -ExpiresAt $session.expiresAt -Username $Credential.GetNetworkCredential().username
}
