Function Stop-OktaSessionRefreshTimer {
    if ($Script:OktaRefreshTimerSubscription) {
        Unregister-Event -SubscriptionId $Script:OktaRefreshTimerSubscription.Id -ErrorAction SilentlyContinue
        Remove-Job -Name $Script:OktaRefreshTimerSubscription.Name -ErrorAction SilentlyContinue
        $Script:OktaRefreshTimerSubscription = $null
    }

    if ($Script:OktaRefreshTimer) {
        $Script:OktaRefreshTimer.Stop()
        $Script:OktaRefreshTimer.Dispose()
        $Script:OktaRefreshTimer = $null
        Write-Verbose "Session refresh timer stopped"
    }
}
