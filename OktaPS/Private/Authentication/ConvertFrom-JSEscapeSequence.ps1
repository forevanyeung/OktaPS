Function ConvertFrom-JSEscapeSequence {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $Sequence
    )

    # Replace \xNN (hexadecimal escape sequences)
    $content = $Sequence -replace '\\x([0-9A-Fa-f]{2})', {[char]([convert]::ToInt32($_.Groups[1].Value, 16))}

    # Replace \uNNNN (Unicode escape sequences)
    $content = $content -replace "\\u([0-9A-Fa-f]{4})", {[char]([convert]::ToInt32($_.Groups[1].Value, 16))}

    # Optionally, handle other common escape sequences
    # Replace escaped backslash (\\), single quote (\'), double quote (\") and other common JS escapes
    $content = $content -replace "\\\\", "\" -replace "\\'", "'" -replace '\\"', '"'

    # Output the decoded content
    Return $content
}
