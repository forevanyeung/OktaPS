# Authentication

## Authentication Methods
OktaPS supports multiple authentication methods including Credential, Authorization Code, PrivateKey, 
and API key. Credential auth is recommended and mimics the process your browser takes. Authorization 
Code uses an OIDC flow and passes the authentication to your browser. PrivateKey also uses an OIDC 
flow, but uses a secret instead of user authentication, this is recommended for machine to machine 
flows. Authorization Code and PrivateKey require prerequisite OIDC setup in Okta Admin prior to first 
use. API key is also supported.

### Credential (Recommended)
Credential authentication has been updated to work with Identity Engine (OIE). Credential auth
emulates the same requests your browser would make to Okta. This is the simplest to set up, 
and gives you the same access you have on the Okta Admin dashboard. 

For backward-compatibility to Classic engine, specify `classic: true` in your yaml config. Note, 
support for Classic orgs is not actively being tested as I do not have access to a Classic org.

```pwsh
Connect-Okta -OktaDomain "https://dev-8675309.okta.com" -Credential "anna.unstoppable"
```

```yml
okta:
  client:
    orgUrl: https://dev-8675309.okta.com
    authorizationMode: Credential
    username: anna.unstoppable
```

### Authorization Code
Authorization code uses OAuth 2.0 to authenticate 
This is not compatible with Okta's SDK YAML config. 

1. Go to Okta Admin → Applications → Create App Integration.
2. Select OIDC - OpenID Connect -> Single-Page Application.
3. Call the application `OktaPS` and set the sign-in redirect URI to `http://localhost:8080/login/callback`.
4. Assign the application to yourself and whomever will sign into it.
5. Grant the scopes you want OktaPS to be able to access, scopes you grant consent to will be authorized if the client
requests them and the admin user has permission for them.

> You can choose to use a different port on localhost for the sign-in redirect URI. But keep the path `/login/callback` the same.

> Okta's default lifetime is 3600 seconds, to get a refresh token without having to re-authenticate, you need to configure 
> the OAuth app to grant refresh tokens, and you also need to request the `offline_access` scope.

Connect to Okta using the following command, or with the YAML configuration file below. The default location of the YAML configuration file is at `~/.okta/okta.yaml`.

```pwsh
Connect-Okta -OktaDomain "https://dev-8675309.okta.com" -ClientId "0oa...7" -Scopes @("okta.users.read", "okta.users.manage") -Port 8080
```

```yml
okta:
  client:
    orgUrl: https://dev-8675309.okta.com
    authorizationMode: AuthorizationCode
    clientId: 0oa...7
    scopes:
      - offline_access
      - okta.users.read
      - okta.users.manage
    port: 8080
```

```pwsh
Connect-Okta -Config okta.yaml
```

### Private Key
You can use a scoped OAuth 2.0 access token for machine to machine automations. Each access token enables the bearer to perform specific actions on specific Okta endpoints, with that ability controlled by which scopes the access token contains. This is compatible with Okta's SDK

Running commands with this authentication will show up as the application in the logs. This authentication method is only available via a saved YAML config file.
```yml
okta:
  client:
    orgUrl: https://dev-8675309.okta.com
    authorizationMode: PrivateKey
    clientId: 0oa...7
    scopes:
      - okta.users.read
      - okta.users.manage
    privateKey: | 
      -----BEGIN PRIVATE KEY-----
      MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDv/B+1r4eOYba5
      ShsCstEFWicGg+3LOk9srMOZ8qNEUp29nb38nM8cgzvW8rU62EdzaU0xF873D714
      ...
      Y4UkdWKaUy+nu6iDa6K1fYlAqdVlLO1gyryBJP2/7FdOQvame4SaBmrTJUuaI/ld
      0Wz1NfLazxP3Ccf5V54zGvta
      -----END PRIVATE KEY-----
```

### API Key
You will need an [API token](https://developer.okta.com/docs/guides/create-an-api-token/main/). API tokens inherit the privilege level of the admin account that is used to create them. It’s therefore good practice to create a service account to use when you create API tokens. With a separate service account, you can assign specific privilege levels to your API tokens.

You can use API key for headless, but need to keep it alive. This is compatible with Okta's SDK.
```pwsh
Connect-Okta -OktaDomain "https://dev-8675309.okta.com" -API "00A...G"
```

```yml
okta:
  client:
    orgUrl: https://dev-8675309.okta.com
    authorizationMode: "SSWS"
    token: 00A...G
```

## YAML Configuration
The OktaPS YAML configuration are compatible with the syntax in Okta's admin management SDKs for PrivateKey and API key methods. Authorization Code and Credential methods have been extended for OktaPS use and are not backwards-compatible.

OktaPS similarly follows the priority of config sources as the Okta SDK, valuing higher numbers.
1. YAML configs 

Search in one of the following locations in order of precedence:
https://developer.okta.com/docs/guides/implement-oauth-for-okta-serviceapp/main/
1. Environment variables (in this case, cmdlet parameters)
2. An okta.yaml file in a .okta folder in the application or project's root directory
3. An okta.yaml file in a .okta folder in the current user's home directory (~/.okta/okta.yaml or %userprofile%\.okta\okta.yaml)
