Function Get-OktaApp {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName="ByApp")]
        [String]
        $App,

        [Parameter(ParameterSetName="ByIdentity")]
        [String]
        $Identity,

        [Parameter(ParameterSetName="ByGroup")]
        [String]
        $Group
    )
    
    If($PSCmdlet.ParameterSetName -like "ByApp") {
        # attempt Id search, fail attempt Name search
        If($App -like "0oa*") {
            $response = Invoke-OktaRequest -Method "GET" -Endpoint "api/v1/apps/$App" -ErrorAction SilentlyContinue
            Write-Verbose "Tried Id search, nothing found."
        }

        # attempt Name search
        If($null -eq $response) {
            $response = Invoke-OktaRequest -Method "GET" -Endpoint "api/v1/apps" -Query @{
                q = $App
            }
        }
    } ElseIf($PSCmdlet.ParameterSetName -like "ByIdentity") {
        # TODO
    } ElseIf($PSCmdlet.ParameterSetName -like "ByGroup") {
        # TODO
    }

    If($response) {
        $OktaApp = ConvertTo-OktaApp -InputObject $response
        Return $OktaApp
    } else {
        Throw "No Okta app found."
    }
}