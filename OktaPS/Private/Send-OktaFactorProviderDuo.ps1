Function Send-OktaFactorProviderDuo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]
        $VerifyUrl,

        [Parameter(Mandatory=$true)]
        [String]
        $StateToken
    )

    $okta_verify = Invoke-RestMethod -Uri $VerifyUrl -Method "POST" -Body (@{
        "stateToken" = $StateToken
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

    $okta_callback = Invoke-RestMethod -Method "POST" -Uri $duo._links.complete.href -Body @{
        "id" = $okta_authn._embedded.factors[0].id
        "stateToken" = $okta_authn.stateToken
        "sig_response" = "$($duo_cookie.response.cookie):$duo_app"
    } -ContentType "application/x-www-form-urlencoded" -WebSession $OktaSSO

    # If($okta_callback) {
        $res = Invoke-RestMethod -Uri $VerifyUrl -Method "POST" -Body (@{
            "stateToken" = $StateToken
        } | ConvertTo-Json) -ContentType "application/json" -WebSession $OktaSSO

        $session_token = $res.sessionToken
    # }

    Return $session_token
}
