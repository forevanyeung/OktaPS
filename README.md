# OktaPS

There are already a handfull of Okta modules out there, why another one? This module acheives the same as any other modules does with two key characterizations
- Authenticating to the Okta API without an API key by using a user session (API key is also supported)
- Mimic the Active Directory cmdlets style with pipelines and format raw JSON response into something more PowerShell-esq

The scope of functions are currently built around reporting and group memberships. New cmdlets are added based upon needs. I do not see adding cmdlets for new users or applications, however if there is enough pressure (or a PR), I am open to suggestions.

### PowerShell Compatibility
For cross-platform support, only PowerShell 7.0+ is supported.