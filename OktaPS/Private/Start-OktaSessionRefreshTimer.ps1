Function Start-OktaSessionRefreshTimer {
    param (
        [int]$CheckIntervalSeconds = 60,
        [int]$RefreshThresholdSeconds = 300
    )

    Stop-OktaSessionRefreshTimer

    $timer = [System.Timers.Timer]::new($CheckIntervalSeconds * 1000)
    $timer.AutoReset = $true

    $action = {
        if ($Script:OktaAuthorizationMode -ne "Credential") {
            return
        }
        if (-not $Script:OktaSSOExpirationUTC) {
            return
        }

        $nowUTC = (Get-Date).ToUniversalTime()
        $timeLeft = ($Script:OktaSSOExpirationUTC - $nowUTC).TotalSeconds

        if ($timeLeft -le $Event.MessageData) {
            Write-Verbose "Okta session expiring in $([int]$timeLeft)s, refreshing..."
            Update-OktaAuthentication -RefreshOnly
        }
    }

    $Script:OktaRefreshTimer = $timer
    $Script:OktaRefreshTimerSubscription = Register-ObjectEvent -InputObject $timer -EventName "Elapsed" -Action $action -MessageData $RefreshThresholdSeconds
    $timer.Start()

    Write-Verbose "Session refresh timer started (check every ${CheckIntervalSeconds}s, refresh threshold ${RefreshThresholdSeconds}s)"
}
