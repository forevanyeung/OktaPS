Function Set-OktaConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]
        $Path,

        [Parameter(Mandatory=$true)]
        $Config
    )

    If(Test-Path $Path) {
        Write-Warning "Okta config file already exists at $Path, would you like to overwrite it?" -WarningAction Inquire
    } else {
        $null = New-Item -ItemType File -Path $Path -Force
    }

    
    @{
        okta = @{
            client = $saveConfig
        }
    } | ConvertTo-Yaml -OutFile $Path -Force
}
