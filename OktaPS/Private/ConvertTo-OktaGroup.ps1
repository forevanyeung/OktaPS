Function ConvertTo-OktaGroup {
    [CmdletBinding()]
    param (
        [Parameter()]
        [Object[]]
        $InputObject
    )

    Process {
        foreach($OktaGroup in $InputObject) {
            try {
                $OktaGroupObject = [OktaGroup]$OktaGroup
            } catch {
                throw [System.ArgumentException] "Invalid input object. Could not create OktaGroup object."
            }

            # pull profile values to top-level for convenience
            # if profile attr collides with exisitng OktaGroup property, prepend "profile_" before the attr 
            $groupProfile = @{}
            $properties = $OktaGroupObject.psobject.properties.name
            $attributes = $OktaGroup.profile.psobject.properties
            $attributes | Foreach-Object { 
                If($_.Name -in $properties) {
                    $groupProfile["profile_$($_.Name)"] = $_.Value
                } else {
                    $groupProfile[$_.Name] = $_.Value
                }
            }

            # -NotePropertyMembers faster than individually looping -NotePropertyName
            $OktaGroupObject | Add-Member -NotePropertyMembers $groupProfile

            $OktaGroupObject
        }
    }
}
