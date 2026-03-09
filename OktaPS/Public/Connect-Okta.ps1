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
        [Parameter(ParameterSetName = 'CredentialAuth')]
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
            # Default to credential method
            $AuthFlow = "Credential"

            $oktaYAMLPath = Get-OktaConfig -Path $Config -ErrorAction SilentlyContinue
            If([String]::IsNullOrEmpty($oktaYAMLPath)) {
                Break
            }

            Write-Verbose "Connecting to Okta using config file: $oktaYAMLPath"

            $yaml = Get-Content $oktaYAMLPath | ConvertFrom-Yaml
            $authConfig = $yaml.okta.client
            $settingsConfig = $yaml.okta.settings

            If($authConfig.authorizationMode -eq "PrivateKey") {
                $AuthFlow = "PrivateKey"

                $OrgUrl = $authConfig.orgUrl
                $ClientId = $authConfig.clientId
                $Scopes = $authConfig.scopes
                $PrivateKey = $authConfig.privateKey

            } ElseIf($authConfig.authorizationMode -eq "AuthorizationCode") {
                $AuthFlow = "AuthorizationCode"

                $OrgUrl = $authConfig.orgUrl
                $ClientId = $authConfig.clientId
                $Scopes = $authConfig.scopes

                If($authConfig.port) {
                    $Port = $authConfig.port
                }
    
            } ElseIf(($authConfig.authorizationMode -eq "SSWS") -or (-not [String]::IsNullOrEmpty($authConfig.token))) {
                $AuthFlow = "SSWS"

                $OrgUrl = $authConfig.orgUrl
                $API = $authConfig.token
    
            } ElseIf(-not [String]::IsNullOrEmpty($authConfig.username)) {
                $AuthFlow = "Credential"

                $OrgUrl = $authConfig.orgUrl
                $Credential = Get-Credential $authConfig.username

            } Else {
                Write-Error "Unknown authorization mode: $($authConfig.authorizationMode)"
                Write-Error "Defaulting to credential method"
            }

            If($settingsConfig) {
                foreach($s in $settingsConfig.GetEnumerator()) {
                    $Script:OktaSetting[$s.Key] = $s.Value
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
            # Credential auth requires user interaction, so check if in noninteractive mode
            If(-not [Environment]::UserInteractive) {
                Write-Error "Credential auth requires an interactive shell, use Authorization Code auth instead."
            }

            If([String]::IsNullOrEmpty($OrgUrl)) {
                $OrgUrl = Read-Host "Enter Okta domain (with https://)"
            }
            
            #TODO: switch to IDX by default, use classic only if explicitly specified in yaml
            If($authConfig.classic) {
                Write-Verbose "Using Credential (Classic) auth method"
                Connect-OktaCredential -OktaDomain $OrgUrl -Credential $Credential -ErrorAction Stop
            } else {
                Write-Verbose "Using Credential (OIE) auth method"
                Connect-OktaIDX -OktaDomain $OrgUrl -Credential $Credential -ErrorAction Stop

                $saveConfig = @{
                    orgUrl = $OrgUrl
                    username = $Credential.UserName
                }
            }
        }

        Default {
            Write-Error "Unknown authentication flow: $AuthFlow"
        }
    }

    #TODO: fix
    Write-Host "Connected to $($Script:OktaAuth.Domain)"

    If($Save) {
        Set-OktaConfig -Path $SavePath -Config $saveConfig
    }
}
