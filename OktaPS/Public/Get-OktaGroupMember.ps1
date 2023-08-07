Function Get-OktaGroupMember {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]
        $Group
    )

    $OktaGroup = Get-OktaGroup -Name $Group -ErrorAction Stop
    $GroupId = $OktaGroup.id

    $members = Invoke-OktaRequest -Method "GET" -Endpoint "api/v1/groups/$GroupId/users"

    $OktaUsers = Foreach($m in $members) {
        ConvertTo-OktaUser -InputObject $m
    }
   
    Return $OktaUsers
}