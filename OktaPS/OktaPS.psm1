# Powershell module for development. Exports public and private functions. 
# Production module will overwrite this file. 

# Get public and private function definition files
$ModulePath = $PSScriptRoot -eq "" ? $($pseditor.geteditorcontext().currentfile.path | split-path -parent) : $PSScriptRoot
$Public = @( Get-ChildItem -Path $ModulePath\Public -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $ModulePath\Private -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue )

Foreach($fn in @($Public + $Private)) {
    Try {
        Write-Host "Importing function: $($fn.FullName)"
        
        # Dot source the functions
        . $fn.FullName

        # export function
        Export-ModuleMember -Function $fn.BaseName -ErrorAction SilentlyContinue
    } Catch {
        Write-Error -Message "Failed to import function $($fn.FullName): $_"
    }   
}

# Add Types
$ModuleTypes = @( Get-ChildItem -Path $ModulePath\Types\*.type.ps1xml -ErrorAction SilentlyContinue )
Foreach($t in $ModuleTypes) {
    Write-Host "Appending type data: $($t.FullName)"
    Update-TypeData -Append $t
}

# Add Formats
$ModuleFormats = @( Get-ChildItem -Path $ModulePath\Types\*.format.ps1xml -ErrorAction SilentlyContinue )
Foreach($f in $ModuleFormats) {
    Write-Host "Appending format data: $($f.FullName)"
    Update-FormatData -PrependPath $f
}

# Add Classes
$ModuleClasses = @( Get-ChildItem -Path $ModulePath\Types\*.class.ps1 -ErrorAction SilentlyContinue )
Foreach($class in $ModuleClasses) {
    Write-Host "Dot sourcing class: $($class.FullName)"
    . $class.FullName
}

# Import dependency modules
$ModuleImports = @( Get-ChildItem -Path "$ModulePath\pwsh_modules\" -Filter *.psm1 -Recurse -ErrorAction SilentlyContinue )
Foreach($mod in $ModuleImports) {
    Try {
        Write-Host "Importing module: $($mod.FullName)"
        Import-Module $mod -Force
    } Catch {
        Write-Error "Failed to import module $($mod.FullName): $_"
    }
}
