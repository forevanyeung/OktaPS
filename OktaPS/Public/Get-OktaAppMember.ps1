Function Get-OktaAppMember {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName="ByAppId", Mandatory)]
        [String]
        $App,

        [Parameter(ParameterSetName="ByOktaApp", ValueFromPipeline, Mandatory)]
        [PSTypeName("Okta.App")]
        $InputObject
    )

    If($PSCmdlet.ParameterSetName -eq "ByAppId") {
        $OktaApp = Get-OktaApp -App $App
    }

    $response = Invoke-OktaRequest -Method "GET" -Endpoint "api/v1/apps/$($OktaApp.id)/users" -Query @{ limit = 500 }

    $OktaUser = Convertto-OktaAppUser -InputObject $response
    Return $OktaUser
}