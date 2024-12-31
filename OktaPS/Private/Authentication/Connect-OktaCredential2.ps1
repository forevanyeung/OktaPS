Function Connect-OktaCredential2 {
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

    $oktaAdminDomain = Get-OktaAdminDomain -Domain $OktaDomain
    $userAgent = New-UserAgentString

    $idx = Invoke-WebRequest -Uri $oktaAdminDomain -UserAgent $userAgent -SessionVariable OktaSSO
    $authorize = [System.Net.WebUtility]::HtmlDecode($idx.content)
    $authorize = ConvertFrom-JSEscapeSequence -Sequence $authorize
    # $queryString = [System.Web.HttpUtility]::ParseQueryString($idx.BaseResponse.RequestMessage.RequestUri.Query)

    # Use regex to extract the value of `stateToken`
    $regex = "var stateToken = '([^']+)';"
    $hasStateToken = $authorize -match $regex
    If(-not $hasStateToken) {
        Throw "Failed to extract stateToken from the response"
    }
    
    $stateHandle = $matches[1] # Extracted token is in the first capture group

    $introspect = Invoke-RestMethod -Uri "${OktaDomain}/idp/idx/introspect" -Method POST -Body (@{
        "stateToken" = $stateHandle
    } | ConvertTo-Json) -ContentType "application/json" -UserAgent $userAgent -WebSession $OktaSSO

    If($introspect | Get-Member -Name "authenticatorChallenge") {

    }

    $identifyUri = $introspect.remediation.value | Where-Object { $_.name -eq "identify" } | Select-Object -ExpandProperty href
    $identify = Invoke-RestMethod -Uri $identifyUri -Method POST -Body (@{
        "identifier" = $Credential.UserName
        "credentials" = @{
            "passcode" = $Credential.GetNetworkCredential().Password
        }
        "stateHandle" = $stateHandle
    } | ConvertTo-Json) -ContentType "application/json" -UserAgent $userAgent -WebSession $OktaSSO -SkipHttpErrorCheck -StatusCodeVariable statusCode

    $statusCode

    If($statusCode -ne 200) {
        Throw $identify.messages.value.message
    }

    # LOOPBACK (find OV)
    $loopbackDomain = $introspect.authenticatorChallenge.value.domain
    $loopbackPorts = $introspect.authenticatorChallenge.value.ports
    $loopback = Test-Loopback -Hostname $loopbackDomain -Port $loopbackPorts

    If($loopback.success) {
        # CHALLENGE by port (prompt OV)
        $challengeUrl = "$($loopback.address)/$challenge"
        $challenge = Invoke-RestMethod -Uri $challengeUrl -Method POST -Body (@{
            "challengeRequest" = $introspect.authenticatorChallence.value
        } | ConvertTo-Json) -ContentType "application/json"
    } else {
        # CHALLENGE by protocol scheme (prompt OV)
        
    }

    # POLL (wait for OV)
    While($true) {
        $poll = Invoke-RestMethod -Uri $challenge._links.poll.href -Method POST -UserAgent $userAgent -WebSession $OktaSSO
        If($poll.success -eq "SUCCESS") { # FIX
            Break
        }
    }
}
 