function Invoke-OktaUpdateCheck {
    If ($env:OKTAPS_CHECK_UPDATES -eq "false") {
        return
    }

    try {
        $currentModule = $MyInvocation.MyCommand.Module
        $installedVersion = $currentModule.Version

        $onlineVersion = (Find-Module -Name $currentModule.Name -Repository 'PSGallery' -ErrorAction Stop).Version

        If ($onlineVersion -gt $installedVersion) {
            Write-Host -ForegroundColor Yellow "A new version of $($currentModule.Name) is available: $installedVersion -> $onlineVersion. Run 'Update-Module -Name $($currentModule.Name)' to update."
        }
    } catch {
        # Silently ignore update check failures (e.g. no internet, PSGallery unavailable)
    }
}
