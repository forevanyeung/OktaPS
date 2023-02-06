Function ConvertTo-OktaUser {
    # Takes Okta User API response and formats it in OktaUser object. Pulls profile values up to top level.
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, Mandatory)]
        [PSCustomObject[]]
        $InputObject
    )

    Process {
        foreach($OktaUser in $InputObject) {
            try {
                $OktaUserObject = [OktaUser]::new(
                    $OktaUser.id,
                    $OktaUser.status,
                    $OktaUser.profile.firstName,
                    $OktaUser.profile.lastName,
                    $OktaUser.profile.login,
                    ($OktaUser.created ?? [DateTime]::MinValue),
                    ($OktaUser.activated ?? [DateTime]::MinValue),
                    ($OktaUser.statusChanged ?? [DateTime]::MinValue),
                    ($OktaUser.lastLogin ?? [DateTime]::MinValue),
                    ($OktaUser.lastUpdated ?? [DateTime]::MinValue),
                    ($OktaUser.passwordChanged ?? [DateTime]::MinValue)
                    # $OktaUser.type
                )
            } catch {
                throw [System.ArgumentException] "Invalid input object. Could not create OktaUser object."
            }

            # pull profile values to top-level for convinience
            # if profile attr collides with exisitng OktaUser property, prepend "profile_" before the attr 
            # raw profile attr are also set in _profile
            $userProfile = @{}
            $properties = $OktaUserObject.psobject.properties.name
            $attributes = $OktaUser.profile.psobject.properties | Where-Object { $_.name -notin @("firstName", "lastName", "login")}
            $attributes| Foreach-Object { 
                If($_.Name -in $properties) {
                    $userProfile["profile_$($_.Name)"] = $_.Value
                } else {
                    $userProfile[$_.Name] = $_.Value
                }
            }

            # -NotePropertyMembers faster than individually looping -NotePropertyName
            $OktaUserObject | Add-Member -NotePropertyMembers $userProfile

            $OktaUserObject
        }
    }
}
