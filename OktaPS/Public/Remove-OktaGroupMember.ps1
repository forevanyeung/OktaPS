Function Remove-OktaGroupMember {
    <#
    .SYNOPSIS
        Unassigns a user from a group.
    .DESCRIPTION
        Unassigns a user from a group
    .NOTES
        
    .LINK
        https://developer.okta.com/docs/api/openapi/okta-management/management/tag/Group/#tag/Group/operation/unassignUserFromGroup
    .EXAMPLE
        Remove-OktaGroupMember -Group Accounting -Member anna.unstoppable
        Unassigns the user anna.unstoppable from the group Accounting
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline)]
        [OktaGroup]
        $Group,

        [Parameter(Mandatory = $true, Position = 0)]
        [OktaUser[]]
        $User
    )

    Foreach ($u in $User) {
        If ($u.id) {
            Write-Verbose "Removing $($u.login) from $($Group.Name)"
            Invoke-OktaRequest -Method "DELETE" -Endpoint "api/v1/groups/$($Group.id)/users/$($u.id)"
        }
    }
}
