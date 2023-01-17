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

Function Connect-Okta {
    [CmdletBinding(DefaultParameterSetName='SavedConfig')]
    param (
        # Okta organization url beginning with https://
        [Parameter(ParameterSetName = 'CredentialAuth', Mandatory=$True)]
        [Parameter(ParameterSetName = 'APIAuth', Mandatory=$True)]
        [Alias("OktaDomain")]
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
        [Parameter(ParameterSetName = 'APIAuth')]
        [Switch]
        $Save = $false
    )

    $defaultYamlPath = Join-Path $($env:HOME ?? $env:USERPROFILE) ".okta" "okta.yaml"
    Switch($PSCmdlet.ParameterSetName) {
        "SavedConfig" {
            # https://developer.okta.com/docs/guides/implement-oauth-for-okta-serviceapp/main/
            # 1. Environment variables (in this case, cmdlet parameters)
            # 2. An okta.yaml file in a .okta folder in the application or project's root directory
            # 3. An okta.yaml file in a .okta folder in the current user's home directory (~/.okta/okta.yaml or %userprofile%\.okta\okta.yaml)

            If(Test-Path ($oktaYAMLPath = Join-Path ".okta" "okta.yaml")) {
                $useYAML = $true
            } ElseIf(Test-Path ($oktaYAMLPath = $defaultYamlPath)) {
                $useYAML = $true
            }
        
            If($useYAML) {
                Write-Verbose "Connecting to Okta using okta.yaml file: $oktaYAMLPath"

                $yaml = Get-Content $oktaYAMLPath | ConvertFrom-Yaml
                $config = $yaml.okta.client
        
                If($config.authorizationMode -eq "PrivateKey") {
                    $OrgUrl = $config.orgUrl
                    $ClientId = $config.clientId
                    $Scopes = $config.scopes
                    $PrivateKey = $config.privateKey
                    $AuthFlow = "PrivateKey"
        
                } ElseIf(($config.authorizationMode -eq "SSWS") -or (-not [String]::IsNullOrEmpty($config.token))) {
                    $OrgUrl = $config.orgUrl
                    $API = $config.Token
                    $AuthFlow = "SSWS"
        
                } ElseIf(-not [String]::IsNullOrEmpty($config.username)) {
                    $OrgUrl = $config.orgUrl
                    $Credential = Get-Credential $config.username
                    $AuthFlow = "Credential"
                    Write-Verbose $OrgUrl
                } Else {
                    Write-Error "Unknown authorization mode"
                }
            } Else {
                $OrgUrl = Read-Host -Prompt "Enter your Okta organization url (with https://)"
                $AuthFlow = "Credential"
            }
        }

        "APIAuth" { $AuthFlow = "SSWS" }
        "CredentialAuth" { $AuthFlow = "Credential" }
    }

    # Validate OrgUrl
    If(-not $OrgUrl.StartsWith("https://")) {
        Throw "OrgUrl must start with https://"
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
    }

    If($Save) {
        $null = New-Item -ItemType File -Path $defaultYamlPath -Force
        @{
            okta = @{
                client = $saveConfig
            }
        } | ConvertTo-Yaml -OutFile $defaultYamlPath -Force
    }
}
