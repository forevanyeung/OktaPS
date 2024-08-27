$ModuleName = "OktaPS"

If($env:OKTAPS_CHECK_UPDATES -eq "false") {
    Exit
}

$installedVersion = Get-Module -Name $ModuleName -ListAvailable | Select-Object -ExpandProperty Version
$onlineVersion = Find-Module -Name $ModuleName | Select-Object -ExpandProperty Version

If($onlineVersion -gt $installedVersion) {
    Write-Host -ForegroundColor "Yellow" -Object "New version is available: $installedVersion -> $onlineVersion. Run 'Update-Module -Name $ModuleName' to update."
}
