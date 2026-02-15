Function Invoke-IDXForm {
    [CmdletBinding()]
    param (
        [Parameter()]
        [PSCustomObject]
        $IDXForm
    )

    $body = $IDXForm.value | ForEach-Object {
        If ($_.required) {
            @{ $_.name = $_.value }
        }
    }

    Invoke-RestMethod -Method $IDXForm.method -Uri $IDXForm.href -Headers @{
        'Accept'       = $IDXForm.accepts
        'Content-Type' = $IDXForm.produces
    } -Body ($body | ConvertTo-Json)
}



$domain = "https://clearme-admin.okta.com"

$loginPage = Invoke-WebRequest -Uri $domain -SessionVariable OktaSSO

# Step 2: Extract stateToken from the page
if ($loginPage.Content -notmatch "var stateToken = '([^']+)';") {
    throw "Could not find stateToken in the response from $OktaDomain"
}

Write-Verbose "Successfully extracted stateToken from $OktaDomain"
$stateToken = $Matches[1]

# Decode the state token (it's URL encoded with \x instead of %)
$stateToken = $stateToken -replace '\\x', '%'
$stateToken = [System.Uri]::UnescapeDataString($stateToken)

# introspect
$introspect = Invoke-RestMethod -Method POST -Uri "$domain/idp/idx/introspect" -Headers @{
    'Accept'       = 'application/ion+json; okta-version=1.0.0'
    'Content-Type' = 'application/ion+json; okta-version=1.0.0'
} -Body (@{
        stateToken = $stateToken
    } | ConvertTo-Json)

foreach ($remediation in $introspect.remediation.value) {
    if ($remediation.relatesTo) {
        Write-Verbose $remediation.relatesTo

        $relatesTo = $introspect.($remediation.relatesTo).value

        switch ($relatesTo.challengeMethod) {
            'LOOPBACK' {
                [int]$timeout = [Math]::Ceiling($relatesTo.probeTimeoutMillis / 1000)
                foreach ($port in $relatesTo.ports) {
                    # GET domain:port/probe
                    try {
                        Invoke-RestMethod -Uri "$($relatesTo.domain):$($port)/probe" -ConnectionTimeoutSeconds $timeout
                    }
                    catch {
                        Write-Verbose "Connection timed out to: $($relatesTo.domain):$($port)/probe"
                        Continue
                    }

                    Write-Verbose "Sending challenge request to $port"
                    # POST domain:port/challengeRequest
                    # return
                    Return
                }

                # POST cancel
                Invoke-IDXForm -IDXForm $relatesTo.cancel
            }

            default {
                Write-Warning "Unknown challenge method: $($relatesTo.challengeMethod)"
            }
        }
    }

    switch ($remediation.name) {
        'identify' {}                          # Username entry
        'challenge-authenticator' {}           # Password/MFA challenge
        'authenticator-verification-data' {}   # Provide verification code
        'select-authenticator-authenticate' {} # Choose which MFA to use
        # 'select-authenticator-enroll' {}       # Choose which MFA to enroll
        # 'enroll-authenticator' {}              # Enroll new MFA
        'skip' {}                              # Optional step
        'device-challenge-poll' {
            # Poll for Okta Verify
            Write-Host "Waiting for authentication approval, check Okta Verify"
            $refreshInterval = $remediation.refresh ?? 2000

            Invoke-IDXForm -IDXForm $remediation

            Start-Sleep -Milliseconds $refreshInterval
        }
        default {}       
    }
}
