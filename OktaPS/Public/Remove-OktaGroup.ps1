Function Remove-OktaGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OktaGroup]
        $Group
    )

    Invoke-OktaRequest -Method "DELETE" -Endpoint "api/v1/groups/$($Group.id)"
}