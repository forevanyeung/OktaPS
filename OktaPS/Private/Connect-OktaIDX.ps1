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

    $idxStatus = 0
    $customUriOnce = $true
    $i = 0
    :idx while($idxForm) {
        $res = Invoke-IDXForm -IDXForm $idxForm -Value $idxValue -WebSession $OktaSSO
        $idx = $res.idx
        $idxStatus = $res.status

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

        If($idx.psobject.Properties.name -contains "success") {
            # device polling success, clean up
            [Console]::TreatControlCAsInput = $false
            Write-Progress -Complete

            $success = Invoke-WebRequest -Uri $idx.success.href -WebSession $OktaSSO
            $session = Invoke-RestMethod -Uri "$OktaAdminDomain/api/v1/sessions/me" -WebSession $OktaSSO

            If($success.content -match '(?:id="_xsrfToken".*?>)(?<xsrfToken>.*?)(?:<)') {
                If($Matches.xsrfToken.Length -gt 0) {
                    $Script:OktaXSRF = $Matches.xsrfToken
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
            
            Break idx
        }

        foreach ($remediation in $IDX.remediation.value) {
            Write-Verbose "Remediation name: $($remediation.name)"

            # relatesTo
            if ($remediation.psobject.Properties.name -contains "relatesTo") {
                Write-Verbose "Relates to: $($remediation.relatesTo)"

                if ($remediation.relatesTo -eq "$.currentAuthenticator") {
                    $relatesTo = $IDX.currentAuthenticator.value.contextualData.challenge.value
                    $cancel = $IDX.currentAuthenticator.value.cancel
                } else {
                    $relatesTo = $IDX.($remediation.relatesTo).value
                }

                :challenge switch ($relatesTo.challengeMethod) {
                    'LOOPBACK' {
                        [int]$timeout = [Math]::Ceiling($relatesTo.probeTimeoutMillis / 1000)
                        foreach ($port in $relatesTo.ports) {
                            # GET domain:port/probe
                            try {
                                Invoke-RestMethod -Uri "$($relatesTo.domain):$($port)/probe" -ConnectionTimeoutSeconds $timeout -Headers @{
                                    'Accept' = "*/*"
                                    'Origin' = $OktaDomain
                                }
                            }
                            catch {
                                Write-Verbose "Connection timed out to: $($relatesTo.domain):$($port)/probe"
                                Continue
                            }

                            # POST domain:port/challengeRequest
                            Write-Verbose "Sending challenge request to $port"
                            Invoke-RestMethod -Method POST -Uri "$($relatesTo.domain):$($port)/challenge" -Headers @{
                                'Content-Type' = "application/json"
                                'Origin' = $OktaDomain
                            } -Body (@{
                                challengeRequest = $relatesTo.challengeRequest
                            } | ConvertTo-Json)

                            # get out of foreach loop
                            Break challenge
                        }

                        # POST cancel
                        Write-Verbose "Cancel LOOPBACK"
                        # Invoke-IDXForm
                        if ($cancel) {
                            $idxForm = $cancel
                            $idxValue = @{}
                        } else {
                            $idxForm = $relatesTo.cancel
                            $idxValue = @{}
                        }

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
                # 'identify' {}                          # Username entry, use default
                # 'unlock-account' {}                    # Unlock account
                # 'challenge-authenticator' {}           # Password/MFA challenge, use default
                # 'authenticator-verification-data' {}   # Provide verification code
                
                'select-authenticator-authenticate' {  # Choose which MFA to use
                    $authenticator  = $remediation.value | Where-Object { $_.name -eq 'authenticator' }
                    $idxForm = $remediation
                    $idxValue = @{
                        authenticator = Read-OktaIDXFactor -Options $authenticator.options
                    }

                    Continue idx
                }

                # 'select-authenticator-enroll' {}       # Choose which MFA to enroll
                # 'enroll-authenticator' {}              # Enroll new MFA
                # 'skip' {}                              # Optional step    

                { ($_ -eq 'challenge-poll') -or 
                  ($_ -eq 'device-challenge-poll') } {  # Poll for Okta Verify  
                    # check input for ctrl+c to break out of loop and choose different factor
                    If ($Host.UI.RawUI.KeyAvailable -and ($Key = $Host.UI.RawUI.ReadKey("AllowCtrlC,NoEcho,IncludeKeyUp"))) {
                        # Flush the key buffer again for the next loop.
                        $stop = [Int]$Key.Character -eq 3
                        $Host.UI.RawUI.FlushInputBuffer()

                        If ($stop) {
                            Write-Host ""
                            [Console]::TreatControlCAsInput = $False
                            Write-Progress -Completed

                            #TODO: check for other available factors

                            #Invoke-IDXForm - cancel
                            Write-Warning "Polling cancelled, exiting login."
                            $res = Invoke-IDXForm -IDXForm $IDX.cancel -WebSession $OktaSSO
                            Return
                        }
                    }


                    $dotCount = (($i - 1) % 3) + 1
                    $status = "Press Ctrl+C to use a different factor" + "." * $dotCount
                    Write-Progress -Activity "Waiting for Okta Verify approval" -Status $status 

                    # allow stopping the loop with Ctrl+C
                    [Console]::TreatControlCAsInput = $true

                    $refreshInterval = $remediation.refresh ?? 2000
                    Start-Sleep -Milliseconds $refreshInterval

                    $i++

                    #Invoke-IDXForm
                    $idxForm = $remediation
                    $idxValue = @{}

                    Continue idx
                }

                default {
                    # Sleep if refresh is provided, else sleep for 0ms and continue immediately
                    Start-Sleep -Milliseconds ($remediation.refresh ?? 0)

                    #Invoke-IDXForm
                    $idxForm = $remediation
                    $idxValue = Read-OktaIDXForm -Form $remediation.value -Credential $Credential

                    Continue idx
                }
            }
        }
    }
}