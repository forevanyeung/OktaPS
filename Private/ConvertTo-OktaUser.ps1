Function ConvertTo-OktaUser {
    # Takes Okta User API response and formats it in Okta.User object. Pulls profile values up to top level.
    [CmdletBinding()]
    param (
        [Parameter()]
        [PSCustomObject]
        $InputObject
    )

    $OktaUserObject = [PSCustomObject]@{
        PSTypeName      = 'Okta.User'
        id              = $InputObject.id
        status          = $InputObject.status
        created         = $InputObject.created
        activated       = $InputObject.activated
        statusChanged   = $InputObject.statusChanged
        lastLogin       = $InputObject.lastLogin
        lastUpdated     = $InputObject.lastUpdated
        passwordChanged = $InputObject.passwordChanged
        type            = $InputObject.type
        _groups         = $InputObject._groups
        _links          = $InputObject._links
    }

    $properties = $InputObject.psobject.properties.name
    $attributes = $InputObject.profile.psobject.properties.name
    # pull profile attributes up one level
    $attributes | ForEach-Object {
        # Append profile_ to attribute name if exists in properties
        If($_ -in $properties) {
            $_ = "profile_$($_)"
        }

        $OktaUserObject | Add-Member -MemberType NoteProperty -Name $_ -Value $InputObject.profile.$_
    }

    Return $OktaUserObject
}