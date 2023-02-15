#Requires -Modules 'InvokeBuild'

[CmdletBinding(DefaultParameterSetName="Build")]
param (
    [Parameter(ParameterSetName="Publish")]
    [String]
    $NugetServer, 
    
    [Parameter(ParameterSetName="Publish")]
    [String]
    $NugetApiKey
)

$BuildRoot = $BuildRoot ?? (Get-Location).Path                                  # /
Enter-Build {
    # Environment
    $environment = "Build"

    # Import build config
    $config = Import-PowerShellDataFile .\OktaPS.build.psd1

    # Define folders
    $buildFolder = Join-Path $BuildRoot "Build"                                 # /OktaPS/Build/
    $sourceFolder = Join-Path $BuildRoot $config.Module                         # /OktaPS/
    $outputFolder = Join-Path $BuildRoot $config.Output                         # /release/
    $sourceManifestPath = Join-Path $sourceFolder ($config.Module + ".psd1")    # /OktaPS/OktaPS.psd1
    $outputManifestPath = Join-Path $outputFolder ($config.Module + ".psd1")    # /release/OktaPS.psd1
    $pwshModuleFolder = Join-Path $outputFolder "pwsh_modules"                  # /release/pwsh_modules/
    $docsFolder = Join-Path $BuildRoot "Docs"                                   # /Docs/
    $docsReferenceFolder = Join-Path $docsFolder "reference"                    # /Docs/reference/

    # Dot source build functions
    $build = @( Get-ChildItem -Path $buildFolder -Filter "*.ps1" -ErrorAction SilentlyContinue )
    Foreach($import in $build) {
        Try {
            Write-Verbose "Importing function: $($import.FullName)"
            . $import.FullName
        } Catch {
            Write-Error -Message "Failed to import function $($import.FullName): $_"
        }   
    }
}

# Synopsis: Remove
task CleanOutput {
	$null = Remove-Item $outputFolder -Force -Recurse -ErrorAction SilentlyContinue
    Write-Host -NoNewLine "     Cleaning up directory: $outputFolder" 
    $null = New-Item $outputFolder -ItemType Directory
    Write-Host -ForegroundColor Green ' ...Complete!'
}

task CleanPwshModule {
    $null = Remove-Item $pwshModuleFolder -Force -Recurse -ErrorAction SilentlyContinue
    Write-Host -NoNewLine "     Cleaning up directory: $pwshModuleFolder" 
    $null = New-Item $pwshModuleFolder -ItemType Directory
    Write-Host -ForegroundColor Green ' ...Complete!'
}

# Synopsis: Increment the build number
task BumpBuildNumber {
    # Start by importing the manifest to determine the version, then add 1 to the Build
    $manifest = Test-ModuleManifest -Path $sourceManifestPath
    [System.Version]$version = $manifest.Version
    [String]$newVersion = New-Object -TypeName System.Version -ArgumentList ($version.Major, $version.Minor, ($version.Build + 1))
    Write-Host "     New Module version: $newVersion"

    # Update manifest with new version
    Update-ModuleManifest -ModuleVersion $newVersion -Path $sourceManifestPath
}

# Synopsis: 
task CopyModuleManifest {
    Write-Host -NoNewLine "     Validating source manifest"
    $null = Test-ModuleManifest -Path $sourceManifestPath
    Write-Host -ForegroundColor Green "...Complete!"

    Write-Host "     Copying module manifest to output" -NoNewLine
    Copy-Item -Path $sourceManifestPath -Destination $outputFolder
    Write-Host -ForegroundColor Green "...Complete!"

    # Don't do anything to module manifest yet, see UpdateModuleManifest task.
    # Module files need to exists first.
}

# Synopsis: Assemble the module for release
task AssembleModule {
    $types = Join-Path $sourceFolder "Types"
    $classes = Get-ChildItem -Path $types -Filter "*.class.ps1" 
    Write-Host ""
    $CombineFiles += "## CLASSES ## `r`n`r`n"
    $classes | ForEach-Object {
        Write-Host "          $($_.Name)"
        $CombineFiles += (Get-content $_ -Raw) + "`r`n`r`n"
    }
    Write-Host -NoNewLine "     Combining classes source files"
    Write-Host -ForegroundColor Green '...Complete!'

    $private = Join-Path $sourceFolder "Private"
    Write-Host "     Private Source Files: $private"
    $CombineFiles += "## PRIVATE MODULE FUNCTIONS AND DATA ## `r`n`r`n"
    Get-ChildItem $private | ForEach-Object {
        Write-Host "          $($_.Name)"
        $CombineFiles += (Get-content $_ -Raw) + "`r`n`r`n"
    }
    Write-Host -NoNewLine "     Combining private source files"
    Write-Host -ForegroundColor Green '...Complete!'

    $public = Join-Path $sourceFolder "Public"
    $CombineFiles += "## PUBLIC MODULE FUNCTIONS AND DATA ##`r`n`r`n"
    Write-Host  "     Public Source Files: $public"
    $publicFunctions = Get-ChildItem -Path $public
    $publicFunctions | ForEach-Object {
        Write-Host "          $($_.Name)"
        $CombineFiles += (Get-content $_ -Raw) + "`r`n`r`n"
    }
    Write-Host -NoNewline "     Combining public source files"
    Write-Host -ForegroundColor Green '...Complete!'

    $psm1 = Join-Path $outputFolder ($config.Module + ".psm1")
    Set-Content -Path $psm1 -Value $CombineFiles -Encoding UTF8
    Write-Host -NoNewLine '     Combining module functions and data into one PSM1 file'
    Write-Host -ForegroundColor Green '...Complete!'

    # NB: module manifest needs the module to exists or Update-ModuleManifest will fail
    Write-Host -NoNewLine "     Exporting public functions to module manifest"
    Update-ModuleManifest -Path $outputManifestPath -FunctionsToExport $publicFunctions.BaseName
    Write-Host -ForegroundColor Green "...Complete!"
}

task AssembleTypes {
    $typesDoc = [System.Xml.XmlDocument]::new()
    $xmlDeclaration = $typesDoc.CreateXmlDeclaration("1.0", "utf-8", $null)
    [void] $typesDoc.InsertBefore($xmlDeclaration, $typesDoc.DocumentElement)

    $xmlRoot = $typesDoc.CreateElement("Types")
    [void] $typesDoc.AppendChild($xmlRoot)

    $types = Join-Path $sourceFolder "Types"
    Write-Host "     Assembling type XML data"
    Get-ChildItem $types -Filter "*.ps1xml" | ForEach-Object {
        $type = [System.Xml.XmlDocument](Get-Content $_)
        $type.Types.Type | ForEach-Object {
            Write-Host "          $($_.Name)"
            $import = $typesDoc.ImportNode($_, $true)
            [void] $typesDoc.DocumentElement.AppendChild($import);
        }
    }
    Write-Host -ForegroundColor Green "     ...Complete!"

    $typesPath = Join-Path $outputFolder ($config.Module + ".Types.ps1xml")
    $typesDoc.Save($typesPath)

    Write-Host -NoNewLine "     Writing TypesToProcess to module manifest"
    Update-ModuleManifest -Path $outputManifestPath -TypesToProcess ($config.Module + ".Types.ps1xml")
    Write-Host -ForegroundColor Green "...Complete!"
}

task DownloadDependencies {
    $nestedModules = @()
    $config.Dependencies.GetEnumerator() | ForEach-Object {
        $githubUser, $githubRepoRef = $_.Value.Split("/", 2)
        $githubRepoData, $githubRef = $githubRepoRef.Split("#", 2)
        $githubRepo, $githubSubFolder = $githubRepoData.Split("/", 2)


        $githubUrl = "https://api.github.com/repos/${githubUser}/${githubRepo}/zipball/${githubRef}"
        Write-Host "     Downloading dependency: $githubUrl"
        $depDownload = Save-File -Uri $githubUrl
        Write-Host "          Extracting archive"
        Expand-Archive -Path $depDownload -DestinationPath $pwshModuleFolder
        Remove-Item -Path $depDownload -Force

        $depArchive = (Join-Path $pwshModuleFolder (Split-Path -Path $depDownload -LeafBase))
        $module = $_.Key
        Rename-Item -Path $depArchive -NewName $module
        
        # find psm1
        $depModuleLocation = Join-Path $pwshModuleFolder $module $githubSubFolder
        Write-Host "          Looking for module file in $depModuleLocation"
        $depModuleFile = Get-ChildItem -Path $depModuleLocation -Filter "*.psm1"
        If($depModuleFile.Count -eq 1) {
            Write-Host "          Module file: $depModuleFile"
            $nestedModules += (Join-Path "pwsh_modules" $module $githubSubFolder $depModuleFile.Name)
        } else {
            Write-Host "          Found $($depModuleFile.Count) module files, should be equal to 1." -ForegroundColor Yellow
        }
    }

    If($environment -eq "Build") {
        Write-Host -NoNewLine "     Adding nested modules to manifest" 
        Update-ModuleManifest -Path $outputManifestPath -NestedModules $nestedModules
        Write-Host -ForegroundColor Green "...Complete!"
    }
}

# .SYNOPSIS Final updates to module manifest
task UpdateModuleManifest {
    Write-Host -NoNewLine "     Removing Prerelease tag from module manifest"
    Update-ModuleManifest $outputManifestPath -Prerelease " "
    Write-Host -ForegroundColor Green "...Complete!"
}

task PublishInternalNexus {
    If(-not $NugetApiKey) {
        $NugetApiKey = (property NugetApiKey)
        throw "missing nugetapikey"
    }

    If(-not (Test-Path $outputManifestPath)) {
        throw "missing build files, run Invoke-Build first"
    }

    Write-Host -NoNewline "     Looking for PSRepository"
    $repository = Get-PSRepository | Where-Object { $_.PublishLocation -eq $NugetServer } | Select-Object -First 1 -ExpandProperty "Name"
    If(-not $repository) {
        Write-Host -NoNewline "...Registering PSRepository"
        $repository = "Nexus-OktaPS"
        Register-PSRepository -Name $repository -SourceLocation $NugetServer -PublishLocation $NugetServer
    }
    Write-Host -ForegroundColor Green "...Complete!"

    Write-Host -NoNewLine "     Publishing module to repository"
    Publish-Module -Name $outputManifestPath -Repository $repository -NugetApiKey $NugetApiKey
    Write-Host -ForegroundColor Green "...Complete!"
}

task . CleanOutput, 
       BumpBuildNumber, 
       CopyModuleManifest, 
       AssembleModule, 
       AssembleTypes, 
       DownloadDependencies, 
       UpdateModuleManifest

task Install {
        $Script:environment = "Install"
        $Script:pwshModuleFolder = Join-Path $sourceFolder "pwsh_modules"            # /OktaPS/pwsh_modules/
     }, 
     CleanPwshModule, 
     DownloadDependencies

task Publish PublishInternalNexus
