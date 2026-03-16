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
    $lastChallengeRequest = $null
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
            Write-Progress -Complete

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

                Write-Verbose "Challenge method: $($relatesTo.challengeMethod)"

                :challenge switch ($relatesTo.challengeMethod) {
                    'LOOPBACK' {
                        if ($relatesTo.challengeRequest -ne $lastChallengeRequest) {
                            [int]$timeout = [Math]::Ceiling($relatesTo.probeTimeoutMillis / 1000)
                            foreach ($port in $relatesTo.ports) {
                                # GET domain:port/probe
                                try {
                                    $null = Invoke-RestMethod -Uri "$($relatesTo.domain):$($port)/probe" -ConnectionTimeoutSeconds $timeout -Headers @{
                                        'Accept' = "*/*"
                                        'Origin' = $OktaDomain
                                    }
                                }
                                catch {
                                    Write-Verbose "Connection timed out to: $($relatesTo.domain):$($port)/probe"
                                    Continue
                                }

                                # POST domain:port/challengeRequest async so polling can happen in the main loop
                                Write-Verbose "Sending challenge request to $port"
                                $challengeJob = Start-ThreadJob -StreamingHost $Host -ScriptBlock {
                                    $uri = "$(($using:relatesTo).domain):$($using:port)/challenge"
                                    $headers = @{
                                        'Content-Type' = "application/json"
                                        'Origin'       = $using:OktaDomain
                                    }

                                    $body = @{
                                        challengeRequest = $($using:relatesTo).challengeRequest
                                    } | ConvertTo-Json

                                    $null = Invoke-RestMethod -Method POST -Uri $uri -Headers $headers -Body $body
                                }

                                #Create Event to clean up job after complete
                                $null = Register-ObjectEvent -InputObject $challengeJob -EventName "StateChanged" -Action {

                                    #Logic to handle state change
                                    if($sender.State -match "Complete"){
                                        Remove-Job $sender.Id
                                    }

                                    #Unregister event and remove event job
                                    Unregister-Event -SubscriptionId $Event.EventIdentifier
                                    Remove-Job -Name $event.SourceIdentifier

                                    Write-Verbose "Challenge complete, cleaning up job $($sender.Id)"
                                }

                                $lastChallengeRequest = $relatesTo.challengeRequest
                                
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
                            
                        }
                        #TODO: restart remediation based on response
                    }

                    'CUSTOM_URI' {
                        if($customUriOnce) {
                            try {
                                Write-Host "Please open this URL in your browser to complete authentication: "
                                Write-Host ""
                                Write-Host $relatesTo.href
                                Write-Host ""

                                Start-Process $relatesTo.href
                            }
                            catch {
                            }
                            $customUriOnce = $false
                        }
                    }

                    default {}
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
                    $dotCount = (($i - 1) % 3) + 1
                    $status = "Press Q to use a different factor" + "." * $dotCount
                    Write-Progress -Activity "Waiting for Okta Verify approval" -Status $status

                    $refreshInterval = $remediation.refresh ?? 2000
                    if ($i -gt 0) {
                        Write-Verbose "Sleeping for $refreshInterval ms"
                        $elapsed = 0
                        while ($elapsed -lt $refreshInterval) {
                            Start-Sleep -Milliseconds 200
                            $elapsed += 200
                            if ([Console]::KeyAvailable) {
                                $key = [Console]::ReadKey($true)
                                if ($key.KeyChar -eq 'q' -or $key.KeyChar -eq 'Q') {
                                    Write-Host ""
                                    Write-Progress -Completed

                                    #TODO: check for other available factors

                                    Write-Warning "Polling cancelled, exiting login."
                                    $res = Invoke-IDXForm -IDXForm $IDX.cancel -WebSession $OktaSSO
                                    Return
                                }
                            }
                        }
                    }
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