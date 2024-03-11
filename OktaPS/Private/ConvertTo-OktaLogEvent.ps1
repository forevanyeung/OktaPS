Function ConvertTo-OktaLogEvent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Object[]]
        $LogEvent
    )

    $LogEvent | ForEach-Object {
        $actor = ConvertTo-OktaActor $_.actor
        $target = ConvertTo-OktaTarget $_.target

        [LogEvent]@{
            uuid = $_.uuid
            published = $_.published
            eventType = $_.eventType
            version = $_.version
            severity = $_.severity
            legacyEventType = $_.legacyEventType
            displayMessage = $_.displayMessage
            actor = [actor]$actor
            target = @($target)
        }
    }
}
