Function Add-OktaGroupMember {
    <#
    .SYNOPSIS
        Assigns a user to a group.
    .DESCRIPTION
        Assigns a user to a group.
    .NOTES
        
    .LINK
        https://developer.okta.com/docs/api/openapi/okta-management/management/tag/Group/#tag/Group/operation/assignUserToGroup
    .EXAMPLE
        Add-OktaGroupMember -Group Accounting -Member anna.unstoppable
        Assigns the user anna.unstoppable from the group Accounting
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
            Write-Verbose "Adding $($u.login) to $($Group.Name)"
            Invoke-OktaRequest -Method "PUT" -Endpoint "api/v1/groups/$($Group.id)/users/$($u.id)"
        }
    }
}
