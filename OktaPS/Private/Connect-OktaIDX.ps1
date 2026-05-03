Function Connect-OktaIDX {
    [CmdletBinding()]
        param (
            [Parameter(Mandatory)]
            [String]
            $OktaDomain,

            [Parameter(Mandatory)]
            [System.Management.Automation.PSCredential]
            $Credential
        )


    $OktaAdminDomain = Get-OktaAdminDomain -Domain $OktaDomain
    $loginPage = Invoke-WebRequest -Uri $OktaAdminDomain -SessionVariable OktaSSO

    # Step 2: Extract stateToken from the page
    if ($loginPage.Content -notmatch "var stateToken = '([^']+)';") {
        throw "Could not find stateToken in the response from $OktaAdminDomain"
    }

    Write-Verbose "Successfully extracted stateToken from $OktaAdminDomain"
    $stateToken = $Matches[1]

    # Decode the state token (it's URL encoded with \x instead of %)
    $stateToken = $stateToken -replace '\\x', '%'
    $stateToken = [System.Uri]::UnescapeDataString($stateToken)

    # introspect
    $idxForm = @{
        name = "introspect"
        href = "$OktaDomain/idp/idx/introspect"
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

    $idx = Invoke-OktaIDXLoop -IDXForm $idxForm -WebSession $OktaSSO -OktaDomain $OktaDomain -Credential $Credential

    If(-not $idx) {
        Return
    }

    $success = Invoke-WebRequest -Uri $idx.success.href -WebSession $OktaSSO
    $session = Invoke-RestMethod -Uri "$OktaAdminDomain/api/v1/sessions/me" -WebSession $OktaSSO

    If($success.content -match '(?:id="_xsrfToken".*?>)(?<xsrfToken>.*?)(?:<)') {
        If($Matches.xsrfToken.Length -gt 0) {
            $Script:OktaAuth.XSRF = $Matches.xsrfToken
        } else {
            Write-Warning "XSRF token length is 0. Some Okta endpoints might not be available."
        }
    } else {
        Write-Warning "Unable to get XSRF token. Some Okta endpoints might not be available."
    }

    $authentication = @{
        AuthorizationMode = "Credential"
        Session = $OktaSSO
        Domain = $OktaDomain
        ExpiresAt = $session.expiresAt
        UserName = $Credential.UserName
    }
    Set-OktaAuthentication @authentication
    Start-OktaSessionRefreshTimer
}
