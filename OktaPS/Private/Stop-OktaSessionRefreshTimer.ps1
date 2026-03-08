Function Stop-OktaSessionRefreshTimer {
    Unregister-Event -SourceIdentifier "OktaIDXRefreshTimer" -ErrorAction SilentlyContinue
    Remove-Job -Name "OktaIDXRefreshTimer" -ErrorAction SilentlyContinue

    if ($Script:OktaAuth.RefreshTimer) {
        $Script:OktaAuth.RefreshTimer.Stop()
        $Script:OktaAuth.RefreshTimer.Dispose()
        $Script:OktaAuth.RefreshTimer = $null
        Write-Verbose "Session refresh timer stopped"
    }
}
