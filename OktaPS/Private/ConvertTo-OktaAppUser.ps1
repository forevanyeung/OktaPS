Function ConvertTo-OktaAppUser {
    # Takes Okta User API response and formats it in Okta.AppUser object. Pulls profile values up to top level.
    [CmdletBinding()]
    param (
        [Parameter()]
        [PSCustomObject[]]
        $InputObject
    )

    $OktaAppUserCollection = @(foreach($OktaAppUser in $InputObject) {
        $OktaAppUserObject = [PSCustomObject]@{
            PSTypeName      = 'Okta.AppUser'
            id              = $OktaAppUser.id
            externalId      = $OktaAppUser.externalId
            created         = $OktaAppUser.created
            lastUpdated     = $OktaAppUser.lastUpdated
            scope           = $OktaAppUser.scope
            status          = $OktaAppUser.status
            statusChanged   = $OktaAppUser.statusChanged
            passwordChanged = $OktaAppUser.passwordChanged
            syncstate       = $OktaAppuser.syncState
            username        = $OktaAppUser.credentials.userName
            _links          = $OktaAppUser._links
        }

        $properties = $OktaAppUser.psobject.properties.name
        $appProfile    = $OktaAppUser.profile.psobject.properties.name
        # pull profile attributes up one level
        $appProfile | ForEach-Object {
            # Append profile_ to attribute name if exists in properties
            If($_ -in $properties) {
                $_ = "profile_$($_)"
            }

            $OktaAppUserObject | Add-Member -MemberType NoteProperty -Name $_ -Value $OktaAppUser.profile.$_
        }

        $OktaAppUserObject
    })

    Return $OktaAppUserCollection
}