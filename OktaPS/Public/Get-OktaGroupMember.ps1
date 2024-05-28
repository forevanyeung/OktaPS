Function Get-OktaGroupMember {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [OktaGroup]
        $Group
    )

    $members = Invoke-OktaRequest -Method "GET" -Endpoint "api/v1/groups/$($Group.Id)/users"

    $OktaUsers = Foreach($m in $members) {
        ConvertTo-OktaUser -InputObject $m
    }
   
    Return $OktaUsers
}
