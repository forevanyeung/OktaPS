![stable version](https://img.shields.io/badge/development-0.1.0-orange)
![powershell version support](https://img.shields.io/badge/powershell-%3E%3D%207.0.0-blue)
![platform support](https://img.shields.io/badge/platform-windows%20%7C%20macos-lightgrey)

# OktaPS
A PowerShell module for Okta administration. Supports credential, private key, and API authentication and pipelining objects.

## Installation
OktaPS is published to PSGallery, this is the recommended method for installing OktaPS.
```pwsh
Install-Module -Name "OktaPS"
```

You can also run a development build of OktaPS from source. The development build will export public and private functions to be available from the console. Read more about [building OktaPS](./Build/Build.md). 

## Getting Started
1. Connect to your Okta organization with the OrgUrl and your username, PowerShell will prompt you for the password. If you have 2FA enabled on your account, it will automatically send a push notification (Duo only supported at this time). See the Wiki for more authentication options (API or private key).
    ```pwsh
    PS > Connect-Okta -OrgUrl "https://dev-8675309.okta.com" -Username "anna.unstoppable@forevanyeung.com"

    PowerShell credential request
    Enter your credentials.
    Password for user anna.unstoppable@forevanyeung.com: 
    ```
1. You can now run Okta cmdlets. See the Wiki for available commands.
    ```pwsh
    PS > Get-OktaUser -Identity anna.unstoppable
    ```

1. Here's an example with what you can do with pipelining
    ```pwsh
    PS > Get-OktaGroup -Identity Unstoppables | Add-OktaGroupMember -Identity anna.unstoppable
    ```

### Admin APIs
Some functions leverage the admin API from Okta. These are not officially supported in the Okta documentation and should be used with caution and tested

You can disable the warning prompt with the `Set-OktaAdminAPIWarning -Disable` command. 

### PowerShell Compatibility
For cross-platform support, only PowerShell 7.0+ is supported.

## Credits
OktaPS uses code written by other authors. Thank 

https://github.com/JustinGrote/PowerHTML  
HTML Agility Pack implementation in Powershell for parsing and manipulating HTML

https://github.com/anthonyg-1/PSJsonWebToken  
A PowerShell module that contains functions to create, validate, and test JSON Web Tokens (JWT) as well as the creation of JSON Web Keys (JWK).

Okta®, Auth0®, and the Okta® and Auth0® Logos are registered trademarks of Okta, Inc. in the U.S. and other countries.