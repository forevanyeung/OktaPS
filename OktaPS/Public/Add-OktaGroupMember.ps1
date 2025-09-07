Function Add-OktaGroupMember {
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
