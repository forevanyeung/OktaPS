Function ConvertTo-OktaActor {
    [CmdletBinding()]
    param (
        [Parameter()]
        [Object]
        $Actor
    )

    $Actor | ForEach-Object {
        If($null -eq $_) {
            return 
        }
        
        [Actor]::new(
            $_.id,
            $_.type,
            $_.alternateId,
            $_.displayName,
            $_.detailEntry
        )
    }
}
