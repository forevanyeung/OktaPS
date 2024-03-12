Function ConvertTo-OktaTarget {
    [CmdletBinding()]
    param (
        [Parameter()]
        [Object]
        $Target
    )

    $Target | ForEach-Object {
        If($null -eq $_) {
            return 
        }

        [Target]@{
            id = $_.id
            type = $_.type
            alternateId = $_.alternateId
            displayName = $_.displayName
            detailEntry = $_.detailEntry
        }
    }
}
