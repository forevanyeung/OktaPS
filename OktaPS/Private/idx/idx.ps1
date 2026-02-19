# dot source idx files
Write-Host $PSScriptRoot
Write-Host $MyInvocation.MyCommand.Definition
Get-ChildItem -Path $PSScriptRoot -Filter "*.ps1" | ForEach-Object {
    If($_.FullName -eq $MyInvocation.MyCommand.Definition) { 
        Return 
    }
    Write-Verbose "Dot-sourcing: $_"
    . $_
}

If($null -eq $domain -or $null -eq $cred) {
    $domain = Read-Host "Enter Okta domain"
    $adminDomain = Read-Host "Enter admin domain"
    $cred = Get-Credential
}

## Begin
$loginPage = Invoke-WebRequest -Uri $adminDomain -SessionVariable OktaSSO

# Step 2: Extract stateToken from the page
if ($loginPage.Content -notmatch "var stateToken = '([^']+)';") {
    throw "Could not find stateToken in the response from $adminDomain"
}

Write-Verbose "Successfully extracted stateToken from $adminDomain"
$stateToken = $Matches[1]

# Decode the state token (it's URL encoded with \x instead of %)
$stateToken = $stateToken -replace '\\x', '%'
$stateToken = [System.Uri]::UnescapeDataString($stateToken)

# introspect
$idxStatus = 0
$idx = Invoke-RestMethod -Method POST -Uri "$domain/idp/idx/introspect" -Headers @{
    'Accept'       = 'application/ion+json; okta-version=1.0.0'
    'Content-Type' = 'application/ion+json; okta-version=1.0.0'
} -Body (@{
    stateToken = $stateToken
} | ConvertTo-Json) -WebSession $OktaSSO -SkipHttpErrorCheck -StatusCodeVariable idxStatus

$customUriOnce = $true
:idx while($idx) {
    #TODO: move IDXForm here

    If($idx.psobject.Properties.name -contains "messages") {
        $idx.messages.value | ForEach-Object {
            If($_.class -eq "ERROR") {
                Write-Error $_.message
            } else {
                Write-Host $_.message
            }
        }
    }

    Write-Verbose "Status code received: $idxStatus"
    If($idxStatus -ge 400) {
        Write-Error $idx
        throw "There was an error"
    }

    foreach ($remediation in $IDX.remediation.value) {
        Write-Verbose "Remediation name $($remediation.name)"

        # relatesTo
        if ($remediation.psobject.Properties.name -contains "relatesTo") {
            Write-Verbose "$($remediation.name) $($remediation.relatesTo)"

            $relatesTo = $IDX.($remediation.relatesTo).value

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

                        # POST domain:port/challengeRequest
                        Write-Verbose "Sending challenge request to $port"
                        Invoke-RestMethod -Method POST -Uri "$($relatesTo.domain):$($port)/challenge" -Headers @{
                            'Content-Type' = "application/json"
                        } -Body (@{
                            challengeRequest = $relatesTo.challengeRequest
                        } | ConvertTo-Json)

                        # get out of foreach loop
                        Return
                    }

                    # POST cancel
                    Write-Verbose "Cancel LOOPBACK"
                    $res = Invoke-IDXForm -IDXForm $relatesTo.cancel
                    $idx = $res.idx
                    $idxStatus = $res.status

                    Continue idx

                    #TODO: restart remediation based on response
                }

                'CUSTOM_URI' {
                    if($customUriOnce) {
                        try {
                            Start-Process $relatesTo.href
                        }
                        catch {
                            Write-Host "Please open this URL in your browser to complete authentication: "
                            Write-Host ""
                            Write-Host $relatesTo.href
                            Write-Host ""
                        }
                        $customUriOnce = $false
                    }
                }

                default {
                    Write-Warning "Unknown challenge method: $($relatesTo.challengeMethod)"
                }
            }
        }

        # remediation
        switch ($remediation.name) {
            'identify' {                          # Username entry
                $value = @{
                    identifier = $cred.UserName
                    credentials = @{
                        passcode = $cred.GetNetworkCredential().password
                    }
                }

                $res = Invoke-IDXForm -IDXForm $remediation -Value $value -WebSession $OktaSSO
                $idx = $res.idx
                $idxStatus = $res.status

                Continue idx
            }

            # 'unlock-account' {}                    # Unlock account
            'challenge-authenticator' {}           # Password/MFA challenge
            'authenticator-verification-data' {}   # Provide verification code
            'select-authenticator-authenticate' {} # Choose which MFA to use
            # 'select-authenticator-enroll' {}       # Choose which MFA to enroll
            # 'enroll-authenticator' {}              # Enroll new MFA
            # 'skip' {}                              # Optional step

            'device-challenge-poll' {               # Poll for Okta Verify
                Write-Host "Waiting for authentication approval, check Okta Verify"
                $refreshInterval = $remediation.refresh ?? 2000

                Start-Sleep -Milliseconds $refreshInterval

                #TODO: move up
                $res = Invoke-IDXForm -IDXForm $remediation -WebSession $OktaSSO
                $idx = $res.idx
                $idxStatus = $res.status

                Continue idx
            }

            default {
                #TODO: erase loop
            }
        }
    }
}