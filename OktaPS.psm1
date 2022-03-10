# Get public and private function definition files
$ModulePath = $PSScriptRoot -eq "" ? $($pseditor.geteditorcontext().currentfile.path | split-path -parent) : $PSScriptRoot
$Public = @( Get-ChildItem -Path $ModulePath\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $ModulePath\Private\*.ps1 -ErrorAction SilentlyContinue )

# Dot source the functions
Foreach($import in @($Public + $Private)) {
    Try {
        Write-Verbose "Importing function: $($import.FullName)"
        . $import.FullName
    } Catch {
        Write-Error -Message "Failed to import function $($import.FullName): $_"
    }   
}

# Export public functions
Foreach($fn in $Public.BaseName) {
    Export-ModuleMember -Function $fn -ErrorAction SilentlyContinue
}

# Add Types
$ModuleTypes = @( Get-ChildItem -Path $ModulePath\Types\*.ps1xml -ErrorAction SilentlyContinue )
Foreach($t in $ModuleTypes) {
    Write-Verbose "Appending type data: $($t.FullName)"
    Update-TypeData -Append $t
}