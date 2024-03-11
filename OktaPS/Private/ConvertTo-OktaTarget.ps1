Function ConvertTo-OktaTarget {
    [CmdletBinding()]
    param (
        [Parameter()]
        [Object]
        $Target
    )

    $Target | ForEach-Object {
        [Target]::new(
            $_.id,
            $_.type,
            $_.alternateId,
            $_.displayName,
            $_.detailEntry
        )
    }
}
