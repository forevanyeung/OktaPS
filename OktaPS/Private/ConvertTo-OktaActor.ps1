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
        
        [Actor]@{
            id = $_.id
            type = $_.type
            alternateId = $_.alternateId
            displayName = $_.displayName
            detailEntry = $_.detailEntry
        }
    }
}
