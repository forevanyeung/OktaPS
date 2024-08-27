$ModuleName = "OktaPS"

If($env:OKTAPS_CHECK_UPDATES -eq "false") {
    Exit
}

$installedVersion = Get-Module -Name $ModuleName -ListAvailable | Select-Object -ExpandProperty Version

# Get the default PSGallery repository
$repository = Get-PSRepository | Where-Object { $_.SourceLocation -eq "https://www.powershellgallery.com/api/v2/" } | select -ExpandProperty Name

$onlineVersion = Find-Module -Name $ModuleName -Repository $repository | Select-Object -ExpandProperty Version

If($onlineVersion -gt $installedVersion) {
    Write-Host -ForegroundColor "Yellow" -Object "New version is available: $installedVersion -> $onlineVersion. Run 'Update-Module -Name $ModuleName' to update."
}
