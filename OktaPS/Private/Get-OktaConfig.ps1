Function Get-OktaConfig {
    [CmdletBinding()]
    param (
        [Parameter()]
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

        # Search for the file in the .okta directory of the current working directory
        If(Test-Path ($configPath = Join-Path ".okta" $Path)) {
            Return $configPath
        }

        # Search for the file in the .okta directory of the user's home directory
        If(Test-Path ($configPath = Join-Path $($env:HOME ?? $env:USERPROFILE) ".okta" $Path)) {
            Return $configPath
        }

        Write-Error "Could not find Okta config file at $Path"
        Return
    }

    # If a path is provided, search in one of the following locations in order of precedence:
    # https://developer.okta.com/docs/guides/implement-oauth-for-okta-serviceapp/main/
    # 1. Environment variables (in this case, cmdlet parameters)
    # 2. An okta.yaml file in a .okta folder in the application or project's root directory
    # 3. An okta.yaml file in a .okta folder in the current user's home directory (~/.okta/okta.yaml or %userprofile%\.okta\okta.yaml)
    
    If(Test-Path ($configPath = Join-Path ".okta" "okta.yaml")) {
        Return $configPath
    }

    If(Test-Path ($configPath = Join-Path ".okta" "okta.yml")) {
        Return $configPath
    }

    If(Test-Path ($configPath = Join-Path $($env:HOME ?? $env:USERPROFILE) ".okta" "okta.yaml")) {
        Return $configPath   
    }

    If(Test-Path ($configPath = Join-Path $($env:HOME ?? $env:USERPROFILE) ".okta" "okta.yml")) {
        Return $configPath   
    }
}
