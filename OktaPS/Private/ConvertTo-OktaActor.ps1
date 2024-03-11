Function ConvertTo-OktaActor {
    [CmdletBinding()]
    param (
        [Parameter()]
        [Object]
        $Actor
    )

    $Actor | ForEach-Object {
        [Actor]::new(
            $_.id,
            $_.type,
            $_.alternateId,
            $_.displayName,
            $_.detailEntry
        )
    }
}
