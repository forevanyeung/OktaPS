Function ConvertTo-OktaGroup {
    # Takes Okta User API response and formats it in Okta.User object. Pulls profile values up to top level.
    [CmdletBinding()]
    param (
        [Parameter()]
        [PSCustomObject]
        $InputObject
    )

    $OktaGroupObject = [PSCustomObject]@{
        PSTypeName            = 'Okta.Group'
        id                    = $InputObject.id
        created               = $InputObject.created
        lastUpdated           = $InputObject.lastUpdated
        lastMembershipUpdated = $InputObject.lastMembershipUpdated
        objectClass           = $InputObject.objectClass
        type                  = $InputObject.type
        _links                = $InputObject._links
    }

    # $properties = $InputObject.psobject.properties.name
    $attributes = $InputObject.profile.psobject.properties.name
    # pull profile attributes up one level
    $attributes | ForEach-Object {
        # Append profile_ to attribute name if exists in properties
        # If($_ -in $properties) {
        #     $_ = "profile_$($_)"
        # }

        $OktaGroupObject | Add-Member -MemberType NoteProperty -Name $_ -Value $InputObject.profile.$_
    }

    Return $OktaGroupObject
}