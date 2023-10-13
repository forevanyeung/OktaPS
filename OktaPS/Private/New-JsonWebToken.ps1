# Copyright 2020 Anthony Guimelli
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# Adapted from https://github.com/anthonyg-1/PSJsonWebToken
# Removed unused parameters and added only private key signing

function New-JsonWebToken {
    <#
    .SYNOPSIS
        Generates a JSON Web Token.
    .DESCRIPTION
        Generates a signed JSON Web Token (JWS) with options for specifying a JWK URI in the header.
    .PARAMETER Claims
        The claims for the token expressed as a hash table.
    .PARAMETER HashAlgorithm
        The hash algorthim for the signature. Acceptable values are SHA256, SHA384, and SHA512. Default value is SHA256.
    .PARAMETER PrivateKey
        The private key to use for signing the token.
    .OUTPUTS
        System.String

            The JSON Web Token is returned as a base64 URL encoded string.
    .LINK
        https://tools.ietf.org/html/rfc7519
        https://tools.ietf.org/html/rfc7515
        https://tools.ietf.org/html/rfc7517
#>
    [CmdletBinding()]
    [OutputType([System.String])]
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$Claims,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet("SHA256", "SHA384", "SHA512")]
        [String]$HashAlgorithm = "SHA256",

        [Parameter(Mandatory = $true, Position = 2)]
        [ValidateNotNullOrEmpty()]
        [String]$PrivateKey
    )

    PROCESS {
        [string]$jwt = ""

        #1. Construct header:
        $rsaAlg = @{
            "SHA256" = "RS256"
            "SHA384" = "RS384"
            "SHA512" = "RS512"
        }

        $header = [ordered]@{typ = "JWT"; alg = $rsaAlg[$HashAlgorithm] ?? "RS256"} | ConvertTo-JwtPart

        #2. Construct payload for RSA:
        $payload = New-JwtPayloadString -Claims $Claims

        #3. Concatenate encoded header and payload seperated by a full stop:
        $jwtSansSig = "{0}.{1}" -f $header, $payload

        #4. Generate signature for concatenated header and payload:
        [string]$rsaSig = ""
        try 
        {
            $rsaSig = New-JwtRsaSignature -JsonWebToken $jwtSansSig -HashAlgorithm $HashAlgorithm -PrivateKey $PrivateKey

            # $rsaSig = New-JwtSignature -JsonWebToken $jwtSansSig -HashAlgorithm $HashAlgorithm -SigningCertificate $SigningCertificate
        }
        catch 
        {
            $cryptographicExceptionMessage = $_.Exception.Message
            $CryptographicException = New-Object -TypeName System.Security.Cryptography.CryptographicException -ArgumentList $cryptographicExceptionMessage
            Write-Error -Exception $CryptographicException -Category SecurityError -ErrorAction Stop

            # Write-Error -Exception $_.Exception -Category InvalidArgument -ErrorAction Stop
        }

        #5. Construct jws:
        $jwt = "{0}.{1}" -f $jwtSansSig, $rsaSig

        return $jwt
    }
}

function New-JwtPayloadString
{
    [CmdletBinding()]
    [OutputType([System.String])]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)][HashTable]$Claims,

        [Parameter(Mandatory=$false,Position=1)]
        [ValidateRange(1,300)]
        [System.Int32]$NotBeforeSkew
    )
    PROCESS
    {
        [string]$payload = ""

        $_claims = [ordered]@{}

        $now = Get-Date
        $currentEpochTime = Convert-DateTimeToEpoch -DateTime $now

        $notBefore = $currentEpochTime
        if ($PSBoundParameters.ContainsKey("NotBeforeSkew"))
        {
            $notBefore = Convert-DateTimeToEpoch -DateTime ($now.AddSeconds(-$NotBeforeSkew))
        }

        $futureEpochTime = Convert-DateTimeToEpoch -DateTime ($now.AddSeconds($TimeToLive))

        $_claims.Add("iat", $currentEpochTime)
        $_claims.Add("nbf", $notBefore)
        $_claims.Add("exp", $futureEpochTime)

        foreach ($entry in $Claims.GetEnumerator())
        {
            if (-not($_claims.Contains($entry.Key)))
            {
                $_claims.Add($entry.Key, $entry.Value)
            }
        }

        $payload = $_claims | ConvertTo-JwtPart

        return $payload
    }
}

function Convert-DateTimeToEpoch
{
    <#
    .SYNOPSIS
        Converts a System.DateTime to an epoch (unix) time stamp.
    .EXAMPLE
        Convert-DateTimeToEpoch

        Returns the current datetime as epoch.
    .EXAMPLE
        $iat = Convert-DateTimeToEpoch
        $nbf = (Get-Date).AddMinutes(-3) | Convert-DateTimeToEpoch
        $exp = (Get-Date).AddMinutes(10) | Convert-DateTimeToEpoch

        $jwtPayload = @{sub="username@domain.com";iat=$iat;nbf=$nbf;exp=$exp}

        $jwtPayloadSerializedAndEncoded = $jwtPayload | ConvertTo-JwtPart

        Generates JWT payload with an iat claim of the current datetime, an nbf claim skewed three minutes in the past, and an expiration of ten minutes in the future from the current datetime.
    .PARAMETER DateTime
        A System.DateTime. Default value is current date and time.
    .INPUTS
        System.DateTime
    .OUTPUTS
        System.Int64
    .LINK
        https://en.wikipedia.org/wiki/Unix_time
        ConvertTo-JwtPart
    #>
    [CmdletBinding()]
    [Alias('GetEpoch')]
    [OutputType([System.Int64])]
    Param
    (
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$true,
                   Position=0)][ValidateNotNullOrEmpty()][Alias("Date")][DateTime]$DateTime=(Get-Date)
    )

    PROCESS
    {
        $dtut = $DateTime.ToUniversalTime()

        [TimeSpan]$ts = New-TimeSpan -Start  (Get-Date "01/01/1970") -End $dtut

        [Int64]$secondsSinceEpoch = [Math]::Floor($ts.TotalSeconds)

        return $secondsSinceEpoch
    }
}

function ConvertTo-JwtPart
{
    <#
    .SYNOPSIS
        Converts an object to a base 64 URL encoded compressed JSON string.
    .DESCRIPTION
        Converts an object to a base 64 URL encoded compressed JSON string. Useful when constructing a JWT header or payload from a InputObject prior to serialization.
    .PARAMETER InputObject
        Specifies the object to convert to a JWT part. Enter a variable that contains the object, or type a command or expression that gets the objects. You can also pipe an object to ConvertTo-JwtPart.
    .EXAMPLE
        $jwtHeader = @{typ="JWT";alg="HS256"}
        $encodedHeader = $jwtHeader | ConvertTo-JwtPart

        Constructs a JWT header from the hashtable defined in the $jwtHeader variable, serializes it to JSON, and base 64 URL encodes it.
    .EXAMPLE
        $header = @{typ="JWT";alg="HS256"}
        $payload = @{sub="someone.else@company.com";title="person"}

        $encodedHeader = $header | ConvertTo-JwtPart
        $encodedPayload = $payload | ConvertTo-JwtPart

        $jwtSansSignature = "{0}.{1}" -f $encodedHeader, $encodedPayload

        $hmacSignature = New-JwtHmacSignature -JsonWebToken $jwtSansSignature -Key "secret"

        $jwt = "{0}.{1}" -f $jwtSansSignature, $hmacSignature

        Constructs a header and payload from InputObjects, serializes and encodes them and obtains an HMAC signature from the resulting joined values.
    .INPUTS
        System.Object
    .OUTPUTS
        System.String
    .LINK
        New-JwtHmacSignature
        New-JsonWebToken
        Test-JsonWebToken
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [ValidateNotNullOrEmpty()][System.Object]$InputObject
    )
    BEGIN {
        $argumentExceptionMessage = "Unable to serialize and base64 URL encode passed InputObject."
        $ArgumentException = New-Object -TypeName ArgumentException -ArgumentList $argumentExceptionMessage
    }
    PROCESS {
        [string]$base64UrlEncodedString = ""
        try {
            $base64UrlEncodedString = $InputObject | ConvertTo-Json -Depth 25 -Compress | ConvertTo-Base64UrlEncodedString
        }
        catch {
            Write-Error -Exception $ArgumentException -Category InvalidArgument -ErrorAction Stop
        }

        return $base64UrlEncodedString
    }
}

Function New-JwtRsaSignature
{
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$false,Position=0)]
        [ValidateLength(16,131072)][Alias("JWT", "Token")][String]$JsonWebToken,

        [Parameter(Position=1,Mandatory=$true)]
        [ValidateSet("SHA256","SHA384","SHA512")]
        [String]$HashAlgorithm,

        [Parameter(Mandatory=$true,Position=2)]
        [String]$PrivateKey
    )

    BEGIN
    {
        $decodeExceptionMessage = "Unable to decode JWT."
        $ArgumentException = New-Object -TypeName ArgumentException -ArgumentList $decodeExceptionMessage
    }

    PROCESS
    {
        [string]$stringSig = ""

        # Test JWT structure:
        [bool]$isValidJwt = Test-JwtStructure -JsonWebToken $JsonWebToken
        if (-not($isValidJwt))
        {
            Write-Error -Exception $ArgumentException -Category InvalidArgument -ErrorAction Stop
        }

        # JWT should only have 2 parts right now:
        if (($JsonWebToken.Split(".").Count) -ne 2)
        {
            Write-Error -Exception $ArgumentException -Category InvalidArgument -ErrorAction Stop
        }

        # Create an instance of the RSAPKCS1SignatureFormatter class that will ultimately be used to generate the signature:
        $rsaSigFormatter = [System.Security.Cryptography.RSAPKCS1SignatureFormatter]::new()

        # Create an instance of the RSACryptoServiceProvider class that will be used to import the private key in a usable format:
        $rsaProvider = [System.Security.Cryptography.RSACryptoServiceProvider]::new()

        # Split the private key into blocks and convert the second block to a byte array:
        $privateKeyBlocks = $privateKey.Split("-", [System.StringSplitOptions]::RemoveEmptyEntries)
        $privateKeyBytes = [System.Convert]::FromBase64String($privateKeyBlocks[1])
        
        $rsaProvider.ImportPkcs8PrivateKey($privateKeyBytes, [ref] $null)
        
        # Set the RSA key to use for signing:
        $rsaSigFormatter.SetKey($rsaProvider)

        # Set the RSA hash algorithm based on the RsaHashAlgorithm passed:
        $rsaSigFormatter.SetHashAlgorithm($HashAlgorithm.ToString())

        # Convert the incoming string $JsonWebToken into a byte array:
        [byte[]]$message = [System.Text.Encoding]::UTF8.GetBytes($JsonWebToken)

        # The byte array that will contain the resulting hash to be signed:
        [byte[]]$messageDigest = $null

        # Create a SHA256, SHA384 or SHA512 hash and assign it to the messageDigest variable:
        switch ($HashAlgorithm)
        {
            "SHA256"
            {
                $shaAlg = [System.Security.Cryptography.SHA256]::Create()
                $messageDigest = $shaAlg.ComputeHash($message)
                break
            }
            "SHA384"
            {
                $shaAlg = [System.Security.Cryptography.SHA384]::Create()
                $messageDigest = $shaAlg.ComputeHash($message)
                break
            }
            "SHA512"
            {
                $shaAlg = [System.Security.Cryptography.SHA512]::Create()
                $messageDigest = $shaAlg.ComputeHash($message)
                break
            }
            default
            {
                $shaAlg = [System.Security.Cryptography.SHA512]::Create()
                $messageDigest = $shaAlg.ComputeHash($message)
                break
            }
        }

        # Create the signature:
        [byte[]]$sigBytes = $null
        try
        {
            $sigBytes = $rsaSigFormatter.CreateSignature($messageDigest)
        }
        catch
        {
            $signingErrorMessage = "Unable to sign $JsonWebToken  with certificate with thumbprint {0}. Ensure that CSP for this certificate is 'Microsoft Enhanced RSA and AES Cryptographic Provider' and try again. Additional error info: {1}" -f $thumbprint, $_.Exception.Message
            Write-Error -Exception ([CryptographicException]::new($signingErrorMessage)) -Category SecurityError -ErrorAction Stop
        }

        # Return the Base64 URL encoded signature:
        $stringSig = ConvertTo-Base64UrlEncodedString -Bytes $sigBytes

        return $stringSig
    }
}

function Test-JwtStructure 
{
    <#
    .SYNOPSIS
        Tests a JWT for structural validity.
    .DESCRIPTION
        Validates that a JSON Web Token is structurally valid by returing a boolean indicating if the passed JWT is valid or not.
    .PARAMETER JsonWebToken
        Contains the JWT to structurally validate.
    .PARAMETER VerifySignaturePresent
        Determines if the passed JWT has three parts (signature being the third).
    .EXAMPLE
        $jwtSansSig = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjEyMzQ1Njc4OTAsIm5hbWUiOiJKb2huIERvZSIsImFkbWluIjp0cnVlfQ"
        Test-JwtStructure -JsonWebToken $jwtSansSig

        Validates the structure of a JWT without a signature.
    .EXAMPLE
        $jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWV9.VG6H-orYnMLknmJajHx1HW9SftqCWeqE3TQ1UArx3Mk"
        Test-JwtStructure -JsonWebToken $jwt

        Validates the structure of a JWT with a signature.
    .NOTES
        By default a passed JWT's header and payload should base 64 URL decoded JSON. The VerifySignaturePresent switch ensures that all three parts exist seperated by a full-stop (header, payload, signature).
    .OUTPUTS
        System.Boolean
    .LINK
        https://tools.ietf.org/html/rfc7519
        https://en.wikipedia.org/wiki/RSA_(cryptosystem)
		https://en.wikipedia.org/wiki/HMAC
    #>
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    Param ( [
        Parameter(Mandatory = $true, ValueFromPipeline = $false, Position = 0)]
        [ValidateLength(16, 131072)]
        [System.String]$JsonWebToken,

        [Parameter(Mandatory = $false, ValueFromPipeline = $false, Position = 1)]
        [Switch]$VerifySignaturePresent
    )
    PROCESS {
        $arrayCellCount = $JsonWebToken.Split(".") | Measure-Object | Select-Object -ExpandProperty Count

        if ($PSBoundParameters.ContainsKey("VerifySignaturePresent")) {
            if ($arrayCellCount -lt 3) {
                return $false
            }
            else {
                $jwtSignature = $JsonWebToken.Split(".")[2]

                if ($jwtSignature.Length -le 8) {
                    return $false
                }
            }
        }
        else {
            if ($arrayCellCount -lt 2) {
                return $false
            }
        }

        # Test deserialization against header:
        $jwtHeader = $JsonWebToken.Split(".")[0]

        if ($jwtHeader.Length -le 8) {
            return $false
        }

        [string]$jwtHeaderDecoded = ""
        try {
            $jwtHeaderDecoded = $jwtHeader | ConvertFrom-Base64UrlEncodedString
        }
        catch {
            return $false
        }

        $jwtHeaderDeserialized = $null
        try {
            $jwtHeaderDeserialized = $jwtHeaderDecoded | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            return $false
        }

        # Per RFC 7515 section 4.1.1, alg is the only required parameter in a JWT header:
        if ($null -eq $jwtHeaderDeserialized.alg) {
            return $false
        }

        # Test deserialization against payload:
        $jwtPayload = $JsonWebToken.Split(".")[1]

        if ($jwtPayload.Length -le 8) {
            return $false
        }

        [string]$jwtPayloadDecoded = ""
        try {
            $jwtPayloadDecoded = $jwtPayload | ConvertFrom-Base64UrlEncodedString
        }
        catch {
            return $false
        }

        try {
            $jwtPayloadDecoded | ConvertFrom-Json -ErrorAction Stop | Out-Null
        }
        catch {
            return $false
        }

        return $true
    }
}

function ConvertFrom-Base64UrlEncodedString
{
<#
    .SYNOPSIS
        Decodes a base 64 URL encoded string.
    .DESCRIPTION
        Decodes a base 64 URL encoded string such as a JWT header or payload.
    .PARAMETER InputString
        The string to be base64 URL decoded.
    .PARAMETER AsBytes
        Instructions this function to return the result as a byte array as opposed to a default string.
    .EXAMPLE
		"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9" | ConvertFrom-Base64UrlEncodedString

		Decodes a JWT header.
    .INPUTS
        System.String

            A string is received by the InputString parameter.
    .OUTPUTS
        System.String

            Returns a base 64 URL decoded string for the given input.
    .LINK
        https://tools.ietf.org/html/rfc4648#section-5
#>

    [CmdletBinding()]
    [OutputType([System.String], [System.Byte[]])]
    [Alias('b64d', 'Decode')]
    param (
        [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$InputString,

        [Parameter(Position=1,Mandatory=$false,ValueFromPipeline=$false,ValueFromPipelineByPropertyName=$false)]
        [switch]$AsBytes
    )

    BEGIN
    {
        $argumentExceptionMessage = "The input is not a valid Base-64 string as it contains a non-base 64 character, more than two padding characters, or an illegal character among the padding characters."
        $ArgumentException = New-Object -TypeName System.ArgumentException -ArgumentList $argumentExceptionMessage
    }
    PROCESS
    {
        try
        {
            $output = $InputString
            $output = $output.Replace('-', '+') # 62nd char of encoding
            $output = $output.Replace('_', '/') # 63rd char of encoding

            switch ($output.Length % 4) # Pad with trailing '='s
            {
                0 { break }# No pad chars in this case
                2 { $output += "=="; break } # Two pad chars
                3 { $output += "="; break } # One pad char
                default { Write-Error -Exception ([ArgumentException]::new("Illegal base64url string!")) -Category InvalidArgument -ErrorAction Stop }
            }

            # Byte array conversion:
            [byte[]]$convertedBytes = [Convert]::FromBase64String($output)
            if ($PSBoundParameters.ContainsKey("AsBytes"))
            {
                return $convertedBytes
            }
            else
            {
                # String to be returned:
                $decodedString = [System.Text.Encoding]::ASCII.GetString($convertedBytes)
                return $decodedString
            }
        }
        catch
        {
            Write-Error -Exception $ArgumentException -Category InvalidArgument -ErrorAction Stop
        }
    }
}

function ConvertTo-Base64UrlEncodedString
{
<#
    .SYNOPSIS
        Base 64 URL encodes an input string.
    .DESCRIPTION
        Base 64 URL encodes an input string required for the payload or header of a JSON Web Token (JWT).
    .PARAMETER InputString
        The string to be base64 URL encoded.
    .PARAMETER Bytes
        The byte array derived from a string to be base64 URL encoded.
    .EXAMPLE
        $jwtPayload = '{"role":"Administrator","sub":"first.last@company.com","jti":"545a310d890F47B9b1F5dc104f782ABD","iat":1551286711,"nbf":1551286711,"exp":1551287011}'
        ConvertTo-Base64UrlEncodedString -InputString $jwtPayload

        Base 64 URL encodes a JSON value.
    .INPUTS
        System.String

            A string is received by the InputString parameter.
    .OUTPUTS
        System.String

            Returns a base 64 URL encoded string for the given input.
    .LINK
        https://tools.ietf.org/html/rfc4648#section-5
#>

    [CmdletBinding()]
    [Alias('b64e', 'Encode')]
    [OutputType([System.String])]
    param (
        [Parameter(Position=0,ParameterSetName="String",Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$InputString,

        [Parameter(Position=1,ParameterSetName="Byte Array",Mandatory=$false,ValueFromPipeline=$false,ValueFromPipelineByPropertyName=$false)]
        [byte[]]$Bytes
    )

    PROCESS
    {
        [string]$base64UrlEncodedString = ""

        if ($PSBoundParameters.ContainsKey("Bytes"))
        {
            try
            {

                $output = [Convert]::ToBase64String($Bytes)
                $output = $output.Split('=')[0] # Remove any trailing '='s
                $output = $output.Replace('+', '-') # 62nd char of encoding
                $output = $output.Replace('/', '_') # 63rd char of encoding

                $base64UrlEncodedString = $output
            }
            catch
            {
                $ArgumentException = New-Object -TypeName System.ArgumentException -ArgumentList $_.Exception.Message
                Write-Error -Exception $ArgumentException -Category InvalidArgument -ErrorAction Stop
            }
        }
        else
        {
            try
            {
                $encoder = [System.Text.UTF8Encoding]::new()

                [byte[]]$inputBytes = $encoder.GetBytes($InputString)

                $base64String = [Convert]::ToBase64String($inputBytes)

                [string]$base64UrlEncodedString = ""
                $base64UrlEncodedString = $base64String.Split('=')[0] # Remove any trailing '='s
                $base64UrlEncodedString = $base64UrlEncodedString.Replace('+', '-'); # 62nd char of encoding
                $base64UrlEncodedString = $base64UrlEncodedString.Replace('/', '_'); # 63rd char of encoding
            }
            catch
            {
                $ArgumentException = New-Object -TypeName System.ArgumentException -ArgumentList $_.Exception.Message
                Write-Error -Exception $ArgumentException -Category InvalidArgument -ErrorAction Stop
            }
        }

        return $base64UrlEncodedString
    }
}



$privateKey = @"
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCopuUhUPCUTYr7
E9UHFc4ELGZQOnOt9otHLQKatEuncoyKiHp7hmyWciUuHi4zHWTsqnriKpAb406B
d6YqrDqGIHijfDnZpqB89u1a58AXGmwtEV4Z+JZ0T7u/GiXbxXWXWv5OQOqvqaN9
oYGjbBOtxBcPxhu+TJhpncZEQieWquFzGSeici5VaS/v6un3MKzv9Bhpnqshj10x
+BzflNhFbyNJqZB6HgfEfeaYplKLpWDhBuSitj/wP7q0KeMvV9Q8SFBOZyJkGxAl
NR3hH5hM4izn1hU+j9TVdv9zdBZRAj0Kri5ptrbcqD9pdS6SKbCJ/Hyz0sZVcpuy
VFTYf8iRAgMBAAECggEANRQhtPSWYvZssUyylQJFzoZyxPlAgxW/C+2cjjgEP3UL
ymXdtpa+AjN2hCc3fxrXMq0M87VVmZFWmeSgRXnjCWea0Ek+o8OPawUD+sJJcHv+
Y8i9hwr3vy+A9UozdBGXSsV2mAZSVmrba6Sy+k3/e4blgy9kd+X/ae4gAkeX0hD+
88JBAULJ0h2KW4RZvVYlBoPejrg73/D9qqBGiGszSBjhT7zJduGHpRx4WcvPnAs9
SUxUx489+LSVwf6oL1IUM9QzVKRYemiLk9/jAWY+zG3AZkHNwzOkuhJrNoebbKSg
JXIpBIfI2D5iTKXflvfPLnTu9Nb6wVonrMNvnRH94QKBgQDX++94WpH8c7S42BDV
5LLbO4pcMFqlSWQQ8vntcd3cCEYcmjvhesmnRgUKYWOLLrRsBZDQX9djjLQKZeyH
zNbNQmYDh+jtlyjQImKFYHly5NFolwSm+E6Wf7G3xyHKn6cNiciUmPjeS8y0KfTg
kdpfPh/2nb2OZ44qUaMp4mWZpQKBgQDH5gHu+5KCmE+nKYq6dwa2tsKWomGndwz4
DRMSZt3vtkUVX3KIsxXwwfCQR2TRitQYeL6pJrI1xvrXK9rITv1lhzircKJVroZ+
T8fcehSIHo7CIZPLf046Eaq0EEYO+PhUlpaiDE6ScL8D+XknF9MgRHzQPElNX0wq
ZbFJiXtHfQKBgBXn6I7laL8ZITBKQdLf4kAYFt1ozhjLi8moSy8JCH6DnFDUV9Rz
trYvhN1bqVP5hbUbD2gDAH6JS81uLwJLBVJGNMCQ7VADr9EEW8e5VDgR+ydHgeJJ
dvcOtoC0QrohXTkjS2O+7CbnuzhetQZ95I8aZvWFZC9oU2P5aboay0E9AoGBAKTx
kHTe1tS10zvu1k7oOfz4LvZWxNeHL4daWntbsBPFRZnOKVbM1vTTQqn6jyEsObh7
oW83w+MF7iMwR5XzP7nP6x3jkb+7g7SkJhkyDtEGzes4A5jt0eGuhDmSGAzwuRAr
Nd4+43KIX8Vqy+JLEWXVvVuh8yZJ1TJCuRghvjyNAoGAHru0NIbBfgsMY6zx6JK9
WXYcWLA1gNntQda6whFqiOd84ad5ArgLu6H+dyBgM9t0G9ORla8tOXpUDb7xpFLQ
xPLhxrRTZMFp6yvq9CLRuBbigfE2cbdZnqpYzattt67/0GNrdAXh8dyAvKzCe5lD
p0prF6vzwEyjcVOPlFj0pE4=
-----END PRIVATE KEY-----
"@