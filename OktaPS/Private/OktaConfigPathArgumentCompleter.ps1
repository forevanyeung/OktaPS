Function OktaConfigPathArgumentCompleter {
    [CmdletBinding()]
    param (
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters
    )

    # Search in one of the following locations in order of precedence:
    # https://developer.okta.com/docs/guides/implement-oauth-for-okta-serviceapp/main/
    # 1. Environment variables (in this case, cmdlet parameters)
    # 2. An okta.yaml file in a .okta folder in the application or project's root directory
    # 3. An okta.yaml file in a .okta folder in the current user's home directory (~/.okta/okta.yaml or %userprofile%\.okta\okta.yaml)

    $location = @(
        (Join-Path (Get-Location) ".okta"),
        (Join-Path $($env:HOME ?? $env:USERPROFILE) ".okta")
    )

    $configs = Foreach($path in $location) {
        If(-not (Test-Path $path)) {
            continue
        }
        
        Get-ChildItem -Path $path -Filter "okta.yaml" -Recurse
        Get-ChildItem -Path $path -Filter "okta.yml" -Recurse
        Get-ChildItem -Path $path -Filter "*.yaml" -Recurse | Where-Object { $_.name -notlike "okta.yaml" }
        Get-ChildItem -Path $path -Filter "*.yml" -Recurse | Where-Object { $_.name -notlike "okta.yml" }
    }

    $configs | Where-Object { $_.name -like "*$wordToComplete*" }
}
