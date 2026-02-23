# PowerShell script to find and concatenate OCaml module files
# Usage
# ./concat.ps1
param(
    [string]$SourceDir = "src",
    [string]$OutputFile = "concatenated_modules.ml",
    [switch]$IncludeTimestamps = $true,
    [switch]$Verbose
)

# Define the list of modules in the desired order
$modules = @(
    "instructions.ml",
    "vm.ml",
    "node.ml",
    "net.ml",
    "snapshot.ml",
    "runtime.ml",
    "digest.ml",
    "builder.ml",
    "meta.ml",
    "queue.ml",
    "stack.ml",
    "state.ml",
    "step.ml"
)

# Check if source directory exists
if (-not (Test-Path $SourceDir)) {
    Write-Error "Source directory '$SourceDir' not found!"
    Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow
    exit 1
}

# Clear or create the output file
$null > $OutputFile

# Add header
$header = @"
(*
 * OCaml Modules Concatenation
 * Generated on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
 * Source directory: $(Resolve-Path $SourceDir)
 * Total modules: $($modules.Count)
 *)

"@
Set-Content -Path $OutputFile -Value $header

# Initialize counters
$foundCount = 0
$missingModules = @()
$foundPaths = @{}

# Process each module
foreach ($module in $modules) {
    if ($Verbose) {
        Write-Host "Searching for $module..." -ForegroundColor Yellow
    }
    
    # Search for the file recursively
    $found = Get-ChildItem -Path $SourceDir -Recurse -File -Filter $module | Select-Object -First 1
    
    if ($found) {
        $foundPaths[$module] = $found.FullName
        $relativePath = Resolve-Path -Path $found.FullName -Relative
        
        if ($Verbose) {
            Write-Host "  Found: $relativePath" -ForegroundColor Green
        }
        
        # Add module header
        Add-Content -Path $OutputFile -Value "(*"
        Add-Content -Path $OutputFile -Value " * Module: $module"
        Add-Content -Path $OutputFile -Value " * Source: $relativePath"
        
        if ($IncludeTimestamps) {
            $lastModified = (Get-Item $found.FullName).LastWriteTime
            Add-Content -Path $OutputFile -Value " * Last modified: $lastModified"
        }
        
        Add-Content -Path $OutputFile -Value " *)"
        Add-Content -Path $OutputFile -Value ""
        
        # Append the file content
        Get-Content -Path $found.FullName | Add-Content -Path $OutputFile
        
        # Add separator
        Add-Content -Path $OutputFile -Value ""
        Add-Content -Path $OutputFile -Value "(* ============================================================ *)"
        Add-Content -Path $OutputFile -Value ""
        
        $foundCount++
    } else {
        if ($Verbose) {
            Write-Host "  NOT FOUND: $module" -ForegroundColor Red
        }
        $missingModules += $module
        
        # Add warning for missing module
        Add-Content -Path $OutputFile -Value "(*"
        Add-Content -Path $OutputFile -Value " * WARNING: Module $module could not be found!"
        Add-Content -Path $OutputFile -Value " *)"
        Add-Content -Path $OutputFile -Value ""
    }
}

# Add footer with summary
$footer = @"
(*
 * === Summary ===
 * Total modules: $($modules.Count)
 * Modules found: $foundCount
 * Modules missing: $($missingModules.Count)
 * Generated on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
 *)

"@
Add-Content -Path $OutputFile -Value $footer

# Display summary
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Total modules: $($modules.Count)" -ForegroundColor White
Write-Host "Modules found: $foundCount" -ForegroundColor Green

if ($missingModules.Count -gt 0) {
    Write-Host "Modules missing:" -ForegroundColor Red
    foreach ($missing in $missingModules) {
        Write-Host "  - $missing" -ForegroundColor Red
    }
}

Write-Host "`nOutput file created: $OutputFile" -ForegroundColor Cyan
Write-Host "Full path: $(Resolve-Path $OutputFile)" -ForegroundColor Cyan

# Optional: Show found files
if ($foundPaths.Count -gt 0) {
    Write-Host "`nFound files:" -ForegroundColor Green
    foreach ($module in $modules) {
        if ($foundPaths.ContainsKey($module)) {
            $relativePath = Resolve-Path -Path $foundPaths[$module] -Relative
            Write-Host "  $module -> $relativePath" -ForegroundColor Gray
        }
    }
}