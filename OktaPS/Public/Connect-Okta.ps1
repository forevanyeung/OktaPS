# process to determine what auth method to use, recommended to only use one
# method and not save both api and credential to config file. so far not able
# to export a websession to file. I'm assuming this is because the [System.Net.CookieContainer]
# is only a pointer to the actual cookies stored somewhere else
#
# 1.  check config for auth method in order of -session-, apikey, credentials
# 2.  -if session is:-
# 2a. -valid, use-
# 2b. -expired, try to renew session with credentials-
# 3.  if api key set, use api
# 4.  if username is set, prompt for credentials
# 4a. -save session to config-
# 5.  if -save param is set, overwrite config with new

# Register the argument completer
Register-ArgumentCompleter -CommandName 'Connect-Okta' -ParameterName 'Config' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    OktaConfigPathArgumentCompleter -commandName $commandName -parameterName $parameterName -wordToComplete $wordToComplete -commandAst $commandAst -fakeBoundParameter $fakeBoundParameter
}

Function Connect-Okta {
    [CmdletBinding(DefaultParameterSetName='SavedConfig')]
    param (
        # Okta organization url beginning with https://
        [Parameter(ParameterSetName = 'CredentialAuth', Mandatory=$True)]
        [Parameter(ParameterSetName = 'APIAuth', Mandatory=$True)]
        [Alias("OktaDomain")]
        [ValidatePattern("^https://", ErrorMessage="URL must begin with https://")]
        [String]
        $OrgUrl,

        # Okta admin credentials
        [Parameter(ParameterSetName = 'CredentialAuth', Mandatory=$True)]
        [PSCredential]
        $Credential,

        # Okta API key
        [Parameter(ParameterSetName = 'APIAuth', Mandatory=$True)]
        [String]
        $API,

        # Save authentication to .yaml config
        [Parameter(ParameterSetName = 'CredentialAuth')]
        [Parameter(ParameterSetName = 'CredentialAuthSave')]
        [Parameter(ParameterSetName = 'APIAuth')]
        [Parameter(ParameterSetName = 'APIAuthSave')]
        [Switch]
        $Save = $false,

        # Path to save .yaml config file, defaults to the user's home directory ~/.okta/okta.yaml
        [Parameter(ParameterSetName = 'CredentialAuthSave')]
        [Parameter(ParameterSetName = 'APIAuthSave')]
        [String]
        $SavePath = (Join-Path $($env:HOME ?? $env:USERPROFILE) ".okta\okta.yaml"),

        # Path to .yaml config file
        [Parameter(ParameterSetName = 'SavedConfig', Position=0)]
        [ArgumentCompleter({ OktaConfigPathArgumentCompleter @args })]
        [String]
        $Config
    )

    Switch($PSCmdlet.ParameterSetName) {
        "SavedConfig" {
            $oktaYAMLPath = Get-OktaConfig -Path $Config
            If(-not [String]::IsNullOrEmpty($oktaYAMLPath)) {
                Write-Verbose "Connecting to Okta using config file: $oktaYAMLPath"

                $yaml = Get-Content $oktaYAMLPath | ConvertFrom-Yaml
                $yamlConfig = $yaml.okta.client

                If($yamlConfig.authorizationMode -eq "PrivateKey") {
                    $OrgUrl = $yamlConfig.orgUrl
                    $ClientId = $yamlConfig.clientId
                    $Scopes = $yamlConfig.scopes
                    $PrivateKey = $yamlConfig.privateKey
                    $AuthFlow = "PrivateKey"
        
                } ElseIf(($yamlConfig.authorizationMode -eq "SSWS") -or (-not [String]::IsNullOrEmpty($yamlConfig.token))) {
                    $OrgUrl = $yamlConfig.orgUrl
                    $API = $yamlConfig.token
                    $AuthFlow = "SSWS"
        
                } ElseIf(-not [String]::IsNullOrEmpty($yamlConfig.username)) {
                    $OrgUrl = $yamlConfig.orgUrl
                    $Credential = Get-Credential $yamlConfig.username
                    $AuthFlow = "Credential"
                    Write-Verbose $OrgUrl
                } Else {
                    Write-Error "Unknown authorization mode: $($yamlConfig.authorizationMode)"
                    Write-Error "Defaulting to credential auth method"
                    $OrgUrl = Read-Host -Prompt "Enter your Okta organization url (with https://)"
                    $AuthFlow = "Credential"
                }
            } Else {
                $OrgUrl = Read-Host -Prompt "Enter your Okta organization url (with https://)"
                $AuthFlow = "Credential"
            }
        }

        "APIAuth" { $AuthFlow = "SSWS" }
        "CredentialAuth" { $AuthFlow = "Credential" }
    }

    Clear-OktaAuthentication
    
    Switch($AuthFlow) {
        "SSWS" {
            Write-Verbose "Using API auth method"
            Connect-OktaAPI -OktaDomain $OrgUrl -API $API -ErrorAction Stop

            $saveConfig = @{
                orgUrl = $OrgUrl
                authorizationMode = "SSWS"
                token = $API
            }
        }

        "PrivateKey" {
            Write-Verbose "Using OAuth 2.0 private key auth method"
            Connect-OktaPrivateKey -OktaDomain $OrgUrl -ClientId $ClientId -Scopes $Scopes -PrivateKey $PrivateKey -ErrorAction Stop
        }

        "Credential" {
            Write-Verbose "Using Credential auth method"
            Connect-OktaCredential -OktaDomain $OrgUrl -Credential $Credential -ErrorAction Stop

            $saveConfig = @{
                orgUrl = $OrgUrl
                username = $Credential.UserName
            }
        }

        Default {
            Write-Error "Unknown authentication flow: $AuthFlow"
        }
    }

    Write-Host "Connected to $OrgUrl"

    If($Save) {
        Set-OktaConfig -Path $SavePath -Config $saveConfig
    }
}
