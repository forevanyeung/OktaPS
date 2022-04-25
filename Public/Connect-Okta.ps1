# process to determine what auth method to use, recommended to only use one
# method and not save both api and credential to config file. so far not able
# to export a websession to file. I'm assuming this is because the [System.Net.CookieContainer]
# is only a pointer to the actual cookies stored somewhere else
#
# 1.  check config for auth method in order of -session-, apikey, credentials
# 2.  -if session is:-
# 2a. -valid, use-
# 2b. -expired, try to renew session with credentials-
# 3.  if api key set, use api
# 4.  if username is set, prompt for credentials
# 4a. -save session to config-
# 5.  if -save param is set, overwrite config with new

Function Connect-Okta {
    [CmdletBinding(DefaultParameterSetName='SavedConfig')]
    param (
        [Parameter(ParameterSetName = 'CredentialAuth', Mandatory=$True)]
        [Parameter(ParameterSetName = 'APIAuth', Mandatory=$True)]
        [String]
        $OktaOrg = $(If($PsCmdlet.ParameterSetName -ne "SavedConfig") { Read-Host -Prompt "Enter Okta organization" }),

        [Parameter(ParameterSetName = 'CredentialAuth', Mandatory=$True)]
        [PSCredential]
        $Credential = $(If($PsCmdlet.ParameterSetName -eq "CredentialAuth") { Get-Credential -Title "Okta Login" -Message "Enter your Okta credentials." }),

        [Parameter(ParameterSetName = 'APIAuth', Mandatory=$True)]
        [String]
        $API,

        [Parameter(ParameterSetName = 'CredentialAuth')]
        [Parameter(ParameterSetName = 'APIAuth')]
        [Switch]
        $Save = $false
    )

    
    Switch($PSCmdlet.ParameterSetName) {
        "SavedConfig" {
            # Read config file
            Switch($PSVersionTable.OS) {
                { $_ -like "Microsoft Windows*" } { $HOMEDIR = $env:USERPROFILE }
                { $_ -like "Darwin*" } { $HOMEDIR = $env:HOME }
            }

            $ConfigPath = Join-Path $HOMEDIR ".oktaPS"
            Try {
                $Config = Get-Content -Raw -LiteralPath $ConfigPath | ConvertFrom-Json
            } Catch {
                Write-Warning "config file not found"
            }

            $OktaOrg = $Config.oktaOrg

            If(-Not ([String]::IsNullOrEmpty($Config.apiKey))) {
                $AuthFlow = "APIAuth"
                $API = $Config.apiKey

            } elseif(-Not ([String]::IsNullOrEmpty($Config.username))) {
                $AuthFlow = "CredentialAuth"
                $Credential = Get-Credential -Title "Okta Login" -Message "Enter your Okta credentials." -UserName $Config.username

            } else {
                Write-Warning ".oktaPS config is invalid"

                # default to credential auth
                $AuthFlow = "CredentialAuth"
                $Credential = Get-Credential -Title "Okta Login" -Message "Enter your Okta credentials."
            }
        }

        "APIAuth" { $AuthFlow = "APIAuth" }
        "CredentialAuth" { $AuthFlow = "CredentialAuth" }
    }

    $OktaDomain = "$OktaOrg.okta.com"
    $OktaAdminDomain = "$OktaOrg-admin.okta.com"
    
    Switch($AuthFlow) {
        "APIAuth" {
            Write-Verbose "Using API auth method"

            # use IWR to create a web session variable
            $null = Invoke-WebRequest -Uri $OktaDomain -SessionVariable OktaSSO
            $OktaSSO.Headers.Add("Authorization", "SSWS $API")

            # test API key is valid
            Try {
                $null = Invoke-WebRequest -Uri "https://$OktaDomain/api/v1/users/me" -Method "GET" -WebSession $OktaSSO
            } Catch {
                throw
            }

            $Script:OktaSSO = $OktaSSO
            $Script:OktaOrg = $OktaOrg
            $Script:OktaDomain = $OktaDomain

            Return
        }

        "CredentialAuth" {
            Write-Verbose "Using Credential auth method"

            $okta_authn = Invoke-RestMethod -Uri "https://$OktaDomain/api/v1/authn" -Method "POST" -Body (@{
                "username" = $Credential.GetNetworkCredential().username
                "password" = $Credential.GetNetworkCredential().password
                "option" = @{
                    "multiOptionalFactorEnroll" = "false"
                    "warnBeforePasswordExpired" = "false"
                }
            } | ConvertTo-Json) -ContentType "application/json" -SessionVariable OktaSSO

            switch ($okta_authn.status) {
                SUCCESS { 
                    # not implemented
                }

                MFA_REQUIRED {
                    # Duo

                    $okta_verify = Invoke-RestMethod -Uri $okta_authn._embedded.factors[0]._links.verify.href -Method "POST" -Body (@{
                        "stateToken" = $okta_authn.stateToken
                    } | ConvertTo-Json) -ContentType "application/json" -WebSession $OktaSSO

                    # Get Duo settings from Okta
                    $duo = $okta_verify._embedded.factor._embedded.verification

                    $duo_signature = $duo.signature.split(':')
                    $duo_tx = $duo_signature[0]
                    $duo_app = $duo_signature[1]

                    # Get Duo session ID
                    $duo_prompt = ""
                    $duo_prompt_sid = ""
                    While($duo_prompt.StatusCode -ne 302) {
                        $duo_prompt_params = @{}
                        if($duo_prompt_sid -ne "") {
                            $duo_prompt_params = @{
                                body = @{
                                    "sid" = $duo_prompt_sid
                                }
                                ContentType = "application/x-www-form-urlencoded"
                                MaximumRedirection = 0 
                                SkipHttpErrorCheck = $True
                                ErrorAction = "SilentlyContinue"
                            }
                        }

                        $duo_prompt = Invoke-WebRequest -Method "POST" -Uri "https://$($duo.host)/frame/web/v1/auth?tx=$duo_tx&parent=http://0.0.0.0:3000/duo&v=2.1" -WebSession $OktaSSO @duo_prompt_params

                        If($duo_prompt.StatusCode -eq 302) {
                            $duo_prompt_sid = $duo_prompt.Headers.Location.split('=')[1]
                            $duo_prompt_sid = [System.Web.HttpUtility]::UrlDecode($duo_prompt_sid)
                        } else {
                            $duo_prompt_sid = ($duo_prompt.Content | ConvertFrom-Html).SelectSingleNode("//input[@name='sid']").Attributes["value"].DeEntitizeValue
                        }
                    }

                    # Send a Duo push to default phone1
                    $duo_push = Invoke-RestMethod -Method "POST" -Uri "https://$($duo.host)/frame/prompt" -Body @{
                        "sid" = $duo_prompt_sid
                        "device" = "phone1"
                        "factor" = "Duo Push"
                        "out_of_date" = "False"
                    } -ContentType "application/x-www-form-urlencoded" -WebSession $OktaSSO -SkipHttpErrorCheck
                    Write-Host "Push notification sent to: phone1"
                    $duo_push_txid = $duo_push.response.txid

                    $duo_approved = $false
                    while(-not $duo_approved) {
                        $duo_push = Invoke-RestMethod -Method "POST" -Uri "https://$($duo.host)/frame/status" -WebSession $OktaSSO -Body @{
                            sid = $duo_prompt_sid
                            txid = $duo_push_txid
                        }

                        switch ($duo_push.response.status_code) {
                            pushed {
                                $duo_approved = $false
                                Write-Verbose $duo_push.response.status
                            }
                            allow { 
                                $duo_cookie = Invoke-RestMethod -Method "POST" -Uri "https://$($duo.host)$($duo_push.response.result_url)" -WebSession $OktaSSO -Body @{ 
                                    sid = $duo_prompt_sid
                                }
                                $duo_approved = $true
                            }
                            Default {
                                $duo_approved = $false
                                Write-Error "Failed to push 2fa: $($duo_push.response.status)"
                            }
                        }
                    }
                }

                Default {
                    Write-Host "Authentication failed, unknown error."
                    Return $okta.status
                }
            }

            $okta_callback = Invoke-RestMethod -Method "POST" -Uri $duo._links.complete.href -Body @{
                "id" = $okta_authn._embedded.factors[0].id
                "stateToken" = $okta_authn.stateToken
                "sig_response" = "$($duo_cookie.response.cookie):$duo_app"
            } -ContentType "application/x-www-form-urlencoded" -WebSession $OktaSSO

            # If($okta_callback) {
                $res = Invoke-RestMethod -Uri $okta_authn._embedded.factors[0]._links.verify.href -Method "POST" -Body (@{
                    "stateToken" = $okta_authn.stateToken
                } | ConvertTo-Json) -ContentType "application/json" -WebSession $OktaSSO

                $session_token = $res.sessionToken

                # Trade session token for a session cookie
                $null = Invoke-WebRequest -Method "GET" -Uri "https://$OktaDomain/login/sessionCookieRedirect?token=$session_token&redirectUrl=https%3A%2F%2F$OktaDomain" -SkipHttpErrorCheck -WebSession $OktaSSO -MaximumRedirection 5


                # Get an XSRF Token
                # 
                $dashboard = Invoke-WebRequest -Method "GET" -Uri "https://$OktaAdminDomain/admin/dashboard" -WebSession $OktaSSO
                If($dashboard.content -match '(?:id="_xsrfToken".*?>)(?<xsrfToken>.*?)(?:<)') {
                    If($Matches.xsrfToken.Length -gt 0) {
                        $Script:OktaXSRF = $Matches.xsrfToken
                    } else {
                        Write-Warning "XSRF token length is 0. Some Okta endpoints might not be available."
                    }
                } else {
                    Write-Warning "Unable to get XSRF token. Some Okta endpoints might not be available."
                }

                $Script:OktaSSO = $OktaSSO
                $Script:OktaSSOExpirationUTC = $res.expiresAt
                $Script:OktaOrg = $OktaOrg
                $Script:OktaDomain = $OktaDomain
                $Script:OktaAdminDomain = $OktaAdminDomain

                Return
            # } else {
            #     Write-Error "Okta auth failed. $($Error[0])"
            # }
        }
    }

}