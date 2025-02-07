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
        [Parameter(ParameterSetName = 'AuthorizationCodeAuth', Mandatory=$True)]
        [Parameter(ParameterSetName = 'CredentialAuth', Mandatory=$True)]
        [Parameter(ParameterSetName = 'APIAuth', Mandatory=$True)]
        [Alias("OktaDomain")]
        [ValidatePattern("^https://", ErrorMessage="URL must begin with https://")]
        [String]
        $OrgUrl,

        # OAuth client ID
        [Parameter(ParameterSetName = 'AuthorizationCodeAuth', Mandatory=$True)]
        [String]
        $ClientId,

        # OAuth scopes
        [Parameter(ParameterSetName = 'AuthorizationCodeAuth', Mandatory=$True)]
        [String[]]
        $Scopes,

        # OAuth redirect port
        [Parameter(ParameterSetName = 'AuthorizationCodeAuth')]
        [Int]
        $Port = 8080,

        # Okta admin credentials
        [Parameter(ParameterSetName = 'CredentialAuth', Mandatory=$True)]
        [PSCredential]
        $Credential,

        # Okta API key
        [Parameter(ParameterSetName = 'APIAuth', Mandatory=$True)]
        [String]
        $API,

        # Save authentication to .yaml config
        [Parameter(ParameterSetName = 'AuthorizationCodeAuth')]
        [Parameter(ParameterSetName = 'CredentialAuth')]
        [Parameter(ParameterSetName = 'APIAuth')]
        [Switch]
        $Save = $false,

        # Path to save .yaml config file, defaults to the user's home directory ~/.okta/okta.yaml
        [Parameter(ParameterSetName = 'AuthorizationCodeAuth')]
        [Parameter(ParameterSetName = 'CredentialAuth')]
        [Parameter(ParameterSetName = 'APIAuth')]
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
            # Default to authorization code method
            $AuthFlow = "AuthorizationCode"

            $oktaYAMLPath = Get-OktaConfig -Path $Config
            If(-not [String]::IsNullOrEmpty($oktaYAMLPath)) {
                Write-Verbose "Connecting to Okta using config file: $oktaYAMLPath"

                $yaml = Get-Content $oktaYAMLPath | ConvertFrom-Yaml
                $yamlConfig = $yaml.okta.client

                If($yamlConfig.authorizationMode -eq "PrivateKey") {
                    $AuthFlow = "PrivateKey"

                    $OrgUrl = $yamlConfig.orgUrl
                    $ClientId = $yamlConfig.clientId
                    $Scopes = $yamlConfig.scopes
                    $PrivateKey = $yamlConfig.privateKey

                } ElseIf($yamlConfig.authorizationMode -eq "AuthorizationCode") {
                    $AuthFlow = "AuthorizationCode"

                    $OrgUrl = $yamlConfig.orgUrl
                    $ClientId = $yamlConfig.clientId
                    $Scopes = $yamlConfig.scopes

                    If($yamlConfig.port) {
                        $Port = $yamlConfig.port
                    }
        
                } ElseIf(($yamlConfig.authorizationMode -eq "SSWS") -or (-not [String]::IsNullOrEmpty($yamlConfig.token))) {
                    $AuthFlow = "SSWS"

                    $OrgUrl = $yamlConfig.orgUrl
                    $API = $yamlConfig.token
        
                } ElseIf(-not [String]::IsNullOrEmpty($yamlConfig.username)) {
                    $AuthFlow = "Credential"

                    $OrgUrl = $yamlConfig.orgUrl
                    $Credential = Get-Credential $yamlConfig.username

                } Else {
                    Write-Error "Unknown authorization mode: $($yamlConfig.authorizationMode)"
                    Write-Error "Defaulting to authorization code method"
                }
            }
        }

        "AuthorizationCodeAuth" { $AuthFlow = "AuthorizationCode" }
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

        "AuthorizationCode" {
            Write-Verbose "Using OAuth 2.0 authoriation code auth method"
            If($Port) {

                Connect-OktaAuthorizationCode -OktaDomain $OrgUrl -ClientId $ClientId -Scopes $Scopes -Port $Port -ErrorAction Stop

                $saveConfig = @{
                    orgUrl = $OrgUrl
                    authorizationMode = "AuthorizationCode"
                    clientId = $ClientId
                    scopes = $Scopes
                    port = $Port
                }
            } else {
                
                Connect-OktaAuthorizationCode -OktaDomain $OrgUrl -ClientId $ClientId -Scopes $Scopes -ErrorAction Stop

                $saveConfig = @{
                    orgUrl = $OrgUrl
                    authorizationMode = "AuthorizationCode"
                    clientId = $ClientId
                    scopes = $Scopes
                }
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

    Write-Host "Connected to $Script:OktaDomain"

    If($Save) {
        Set-OktaConfig -Path $SavePath -Config $saveConfig
    }
}
