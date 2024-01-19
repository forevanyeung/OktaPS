Function Get-OktaConfig {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ArgumentCompleter({ OktaConfigPathArgumentCompleter @args })]
        [String]
        $Path
    )

    # If a path is provided, use it
    If(-not [String]::IsNullOrEmpty($Path)) {
        If(Test-Path $Path) {
            Return $Path
        }

        # if the path is absolute, no use in searching for it
        If([System.IO.Path]::IsPathRooted($Path)) {
            Write-Error "Could not find Okta config file at $Path"
            Return
        }
    }

    $config = OktaConfigPathArgumentCompleter -wordToComplete $Path
    
    If($config.Count -eq 0) {
        Write-Error "Could not find Okta config file"
        Return
    }
    
    Return $config[0].FullName
}
