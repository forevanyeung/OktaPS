Function Add-OktaGroupMember {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $Group,

        [Parameter()]
        [OktaUser[]]
        $Members
    )

    $OktaGroup = Get-OktaGroup -Name $Group -ErrorAction Stop
    $GroupId = $OktaGroup.id

    Foreach($member in $Members) {
        If($member.id) {
            Write-Verbose "Adding $($member.login) to $($OktaGroup.Name)"
            Invoke-OktaRequest -Method "PUT" -Endpoint "api/v1/groups/$GroupId/users/$($member.id)"
        }
    }
}
