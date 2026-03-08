Function Get-OktaPrivateVariables {
    @(
        $Script:OktaAuth.GetEnumerator()   | ForEach-Object { [PSCustomObject]@{ Component = 'Auth';   Setting = $_.Key; Value = $_.Value } }
        $Script:OktaConfig.GetEnumerator() | ForEach-Object { [PSCustomObject]@{ Component = 'Config'; Setting = $_.Key; Value = $_.Value } }
    ) | Sort-Object Component, Setting | Format-Table -AutoSize
}
