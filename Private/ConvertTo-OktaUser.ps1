Function ConvertTo-OktaUser {
    # Takes Okta User API response and formats it in Okta.User object. Pulls profile values up to top level.
    [CmdletBinding()]
    param (
        [Parameter()]
        [PSCustomObject[]]
        $InputObject
    )

    $OktaUserCollection = @(foreach($OktaUser in $InputObject) {
        $OktaUserObject = [PSCustomObject]@{
            PSTypeName      = 'Okta.User'
            id              = $OktaUser.id
            status          = $OktaUser.status
            created         = $OktaUser.created
            activated       = $OktaUser.activated
            statusChanged   = $OktaUser.statusChanged
            lastLogin       = $OktaUser.lastLogin
            lastUpdated     = $OktaUser.lastUpdated
            passwordChanged = $OktaUser.passwordChanged
            type            = $OktaUser.type
            _groups         = $OktaUser._groups
            _links          = $OktaUser._links
        }

        $properties = $OktaUser.psobject.properties.name
        $attributes = $OktaUser.profile.psobject.properties.name
        # pull profile attributes up one level
        $attributes | ForEach-Object {
            # Append profile_ to attribute name if exists in properties
            If($_ -in $properties) {
                $_ = "profile_$($_)"
            }

            $OktaUserObject | Add-Member -MemberType NoteProperty -Name $_ -Value $OktaUser.profile.$_
        }

        $OktaUserObject
    })

    Return $OktaUserCollection
}