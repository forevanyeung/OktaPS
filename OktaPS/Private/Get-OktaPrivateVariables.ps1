Function Get-OktaPrivateVariables {
    @(
        $Script:OktaAuth.GetEnumerator()   | ForEach-Object { [PSCustomObject]@{ Component = 'Auth';   Setting = $_.Key; Value = $_.Value } }
        $Script:OktaSetting.GetEnumerator() | ForEach-Object { [PSCustomObject]@{ Component = 'Setting'; Setting = $_.Key; Value = $_.Value } }
    ) | Sort-Object Component, Setting
}
