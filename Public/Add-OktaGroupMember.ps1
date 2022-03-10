Function Add-OktaGroupMember {
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

    Foreach($m in $Members) {
        $member = Get-OktaUser -Identity $m
        If($member.id) {
            Write-Verbose "Adding $($member.login) to $($OktaGroup.Name)"
            Invoke-OktaRequest -Method "PUT" -Endpoint "api/v1/groups/$GroupId/users/$($member.id)"
        }
    }
    
}