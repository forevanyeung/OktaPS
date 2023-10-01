Function ConvertTo-OktaGroup {
    # Takes Okta User API response and formats it in Okta.User object. Pulls profile values up to top level.
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, Mandatory)]
        [PSCustomObject[]]
        $InputObject
    )

    Process {
        foreach($OktaGroup in $InputObject) {
            try {
                $OktaGroupObject = [OktaGroup]::new(
                    $OktaGroup.id,
                    $OktaGroup.profile.name,
                    $OktaGroup.profile.description,
                    $OktaGroup.type
                    # created               = $InputObject.created
                    # lastUpdated           = $InputObject.lastUpdated
                    # lastMembershipUpdated = $InputObject.lastMembershipUpdated
                    # objectClass           = $InputObject.objectClass
                    # _links                = $InputObject._links
                )
            } catch {
                throw [System.ArgumentException] "Invalid input object. Could not create OktaGroup object."
            }

            # pull profile values to top-level for convinience
            # if profile attr collides with exisitng OktaUser property, prepend "profile_" before the attr 
            # raw profile attr are also set in _profile
            $groupProfile = @{}
            $properties = $OktaGroupObject.psobject.properties.name
            $attributes = $OktaGroup.profile.psobject.properties | Where-Object { $_.name -notin @("name", "description")}
            $attributes| Foreach-Object { 
                If($_.Name -in $properties) {
                    $groupProfile["profile_$($_.Name)"] = $_.Value
                } else {
                    $groupProfile[$_.Name] = $_.Value
                }
            }

            # -NotePropertyMembers faster than individually looping -NotePropertyName
            if($groupProfile.Count -gt 0) {
                $OktaGroupObject | Add-Member -NotePropertyMembers $groupProfile
            }

            $OktaGroupObject
        }
    }
}
