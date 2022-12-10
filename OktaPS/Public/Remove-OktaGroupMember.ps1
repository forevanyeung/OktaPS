Function Remove-OktaGroupMember {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $Group,
        
        [Parameter()]
        [String[]]
        $Members
    )

    $OktaGroup = Get-OktaGroup -Identity $Group -ErrorAction Stop
    $GroupId = $OktaGroup.id

    Foreach($memberId in $Members) {
        # Invoke-OktaRequest -Method "GET" -Endpoint "/api/v1/users/$member"
        Write-Verbose "Removing $memberId from $($OktaGroup.Name)"
        Invoke-OktaRequest -Method "DELETE" -Endpoint "/api/v1/groups/$GroupId/users/$memberId"
    }
    
}