Function Invoke-OktaStepUp {
    [CmdletBinding()]
    param (
        [Parameter()]
        [Int]
        $MaxAge = 60,

        [Parameter()]
        [String]
        $AcrValues = "urn:okta:loa:2fa:any"
    )

    If(-not $Script:OktaAuth.SSO) {
        Throw "No active Okta session. Run Connect-Okta first."
    }

    If($Script:OktaAuth.AuthorizationMode -ne 'Credential') {
        Throw "Step-up authentication is only supported with Credential authorization mode. Current mode: $($Script:OktaAuth.AuthorizationMode)"
    }

    $session = $Script:OktaAuth.SSO
    $domain = $Script:OktaAuth.Domain
    $adminDomain = $Script:OktaAuth.AdminDomain

    # /admin/sso/step-up 302s to /oauth2/v1/authorize with the supplied OIDC
    # params; existing session cookies are present, but stale max_age forces
    # a re-auth that flows through the IDX login page. This is what the
    # browser navigates to in the popup window for step-up.
    $query = "max_age=$MaxAge&acr_values=$([System.Uri]::EscapeDataString($AcrValues))"
    $entryUrl = "$adminDomain/admin/sso/step-up?$query"
    Write-Verbose "Navigating to step-up entry: $entryUrl"
    $loginPage = Invoke-WebRequest -Uri $entryUrl -WebSession $session -MaximumRedirection 10
    $finalUrl = $loginPage.BaseResponse.RequestMessage.RequestUri.AbsoluteUri
    Write-Verbose "Step-up entry landed on: $finalUrl"

    # If the redirect chain landed on the OIDC callback with an auth code, the
    # existing session already had recent enough MFA — authorize completed and
    # the callback handler stamped the elevated session cookies. We're done.
    If($finalUrl -match '/admin/sso/callback\?.*code=') {
        Write-Verbose "Step-up authentication complete; session elevated via existing MFA."
        Return
    }

    If($loginPage.Content -notmatch "var stateToken\s*=\s*'([^']+)';") {
        $snippet = $loginPage.Content
        If($snippet.Length -gt 1500) { $snippet = $snippet.Substring(0, 1500) }
        Write-Verbose "Response snippet:`n$snippet"
        Throw "Could not find stateToken in step-up response. Final URL: $finalUrl. Re-run with -Verbose to see a content snippet."
    }

    $stateToken = $Matches[1]
    $stateToken = $stateToken -replace '\\x', '%'
    $stateToken = [System.Uri]::UnescapeDataString($stateToken)

    $idxForm = @{
        name = "introspect"
        href = "$domain/idp/idx/introspect"
        method = "POST"
        produces = "application/ion+json; okta-version=1.0.0"
        accepts = "application/ion+json; okta-version=1.0.0"
        value = @(
            @{
                name = "stateToken"
                required = $true
                value = $stateToken
            }
        )
    }

    # Run the IDX state machine on the existing session. Password is already
    # valid via session cookies, so typically only an MFA remediation is shown.
    # If a password prompt does appear (e.g. session cookie expired the password
    # factor), Read-OktaIDXForm will prompt interactively since no Credential
    # is passed.
    $idx = Invoke-OktaIDXLoop -IDXForm $idxForm -WebSession $session -OktaDomain $domain

    If(-not $idx) {
        Throw "Step-up authentication did not complete."
    }

    # Follow the OIDC callback chain. Completing this is what stamps the
    # existing session with the required acr_values.
    $null = Invoke-WebRequest -Uri $idx.success.href -WebSession $session -MaximumRedirection 10
    Write-Verbose "Step-up authentication complete; session elevated."
}
