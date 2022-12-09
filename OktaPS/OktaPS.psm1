# Powershell module for development. Exports public and private functions. 
# Production module will overwrite this file. 

# Get public and private function definition files
$ModulePath = $PSScriptRoot -eq "" ? $($pseditor.geteditorcontext().currentfile.path | split-path -parent) : $PSScriptRoot
$Public = @( Get-ChildItem -Path $ModulePath\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $ModulePath\Private\*.ps1 -ErrorAction SilentlyContinue )

Foreach($import in @($Public + $Private)) {
    Try {
        Write-Verbose "Importing function: $($import.FullName)"
        
        # Dot source the functions
        . $import.FullName

        # export function
        Export-ModuleMember -Function $import.BaseName -ErrorAction SilentlyContinue
    } Catch {
        Write-Error -Message "Failed to import function $($import.FullName): $_"
    }   
}

# Add Types
$ModuleTypes = @( Get-ChildItem -Path $ModulePath\Types\*.ps1xml -ErrorAction SilentlyContinue )
Foreach($t in $ModuleTypes) {
    Write-Verbose "Appending type data: $($t.FullName)"
    Update-TypeData -Append $t
}
