Function Remove-OktaGroupMember {
    [CmdletBinding()]
    param (
        [Parameter()]
        [OktaGroup]
        $Group,
        
        [Parameter()]
        [OktaUser[]]
        $Members
    )

    Foreach($member in $Members) {
        # Invoke-OktaRequest -Method "GET" -Endpoint "/api/v1/users/$member"
        Write-Verbose "Removing $($member.Id) from $($Group.Name)"
        Invoke-OktaRequest -Method "DELETE" -Endpoint "/api/v1/groups/$($Group.Id)/users/$($member.Id)"
    }    
}
