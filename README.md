![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/OktaPS)
![powershell version support](https://img.shields.io/badge/powershell-%3E%3D%207.2.7-blue)
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
Recommened to use Authorization Code method for authentication. This method is the most versatile and supports FastPass. 

1. Create an OIDC app for OktaPS in your organization if this is the first time, if this has already been done, you can use the same app, remember to assign yourself to the app. More information on how to configure an OIDC app, see [Authentication](Authentication#Authorization_Code__Recommended_).
2. Replace the Okta domain with your won and copy the Client Id from the OIDC app to authenticate.
    ```pwsh
    Connect-Okta -OktaDomain "https://dev-8675309.okta.com" -ClientId "0oa...7" -Scopes @("okta.users.read", "okta.users.manage") -Port 8080
    ```
3. You are now ready to execute OktaPS cmdlets. This first example gets a user with the username anna.unstoppable, replace the username with your own and give it a try. 
    ```pwsh
    Get-OktaUser -Identity anna.unstoppable
    ```

4. Here's an example of how to pipe the results of one command into another:
    ```pwsh
    Get-OktaGroup -Identity Unstoppables | Add-OktaGroupMember -Identity anna.unstoppable
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
