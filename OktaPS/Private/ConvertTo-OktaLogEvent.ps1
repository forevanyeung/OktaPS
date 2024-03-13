Function ConvertTo-OktaLogEvent {
    [CmdletBinding()]
    param (
        [Parameter()]
        [Object[]]
        $LogEvent
    )

    $LogEvent | ForEach-Object {
        If($null -eq $_) {
            return 
        }

        $actor = ConvertTo-OktaActor $_.actor
        $target = ConvertTo-OktaTarget $_.target

        [LogEvent]@{
            uuid = $_.uuid
            published = $_.published.ToLocalTime()
            eventType = $_.eventType
            version = $_.version
            severity = $_.severity
            legacyEventType = $_.legacyEventType
            displayMessage = $_.displayMessage
            actor = $actor
            target = @($target)
            client = [Client]$_.client
            request = [Request]$_.request
            outcome = [Outcome]$_.outcome
            # transaction = [Transaction]$_.transaction
            # debugContext = [DebugContext]$_.debugContext
            authenticationContext = [AuthenticationContext]$_.authenticationContext
            securityContext = [SecurityContext]$_.securityContext
        }
    }
}
