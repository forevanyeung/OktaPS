Function Get-OktaGroupMember {
    <#
    .SYNOPSIS
        Lists all users that are a member of a group.
    .DESCRIPTION
        The Get-OktaGroupMember cmdlet lists all users that are a member of a group.

        The Group parameter accepts an OktaGroup object, the Id of a group, or the name of a group.
    .NOTES
        
    .LINK
        https://developer.okta.com/docs/api/openapi/okta-management/management/tag/Group/#tag/Group/operation/listGroupUsers
    .EXAMPLE
        Get-OktaGroupMember -Group Accounting
        Lists all users that are a member of the Accounting group
    #>
    
    [CmdletBinding()]
    param (
        # Specifies an Id or name of an Okta group to retrieve.
        [Parameter(Mandatory = $true, ValueFromPipeline)]
        [OktaGroup]
        $Group
    )

    $query = @{ limit = 200 }

    $members = Invoke-OktaRequest -Method "GET" -Endpoint "api/v1/groups/$($Group.Id)/users" -Query $query

    $OktaUsers = Foreach ($m in $members) {
        ConvertTo-OktaUser -InputObject $m
    }
   
    Return $OktaUsers
}
