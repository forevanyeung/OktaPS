Function Write-OktaAdminAPIWarning {
    If(-not $Script:SuppressAdminAPIWarning) {
        Write-Warning "This makes unoffical admin API calls to Okta, see README for more info. To stop these warnings, use `Set-OktaAdminAPIWarning -Disable`." -WarningAction Inquire
    }
}