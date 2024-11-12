# If less than two arguments are provided, prompt the user for folder paths
if ($args.Count -lt 2) {
    Write-Host "Please enter the path for the first folder:"
    $Folder1 = Read-Host
    Write-Host "Please enter the path for the second folder:"
    $Folder2 = Read-Host
} else {
    $Folder1 = $args[0]
    $Folder2 = $args[1]
}

# Check if the folders exist
if (-not (Test-Path -Path $Folder1 -PathType Container)) {
    Write-Host "Error: Folder '$Folder1' does not exist."
    exit
}

if (-not (Test-Path -Path $Folder2 -PathType Container)) {
    Write-Host "Error: Folder '$Folder2' does not exist."
    exit
}

# Get the subdirectories in each folder
$SubDirs1 = Get-ChildItem -Path $Folder1 -Directory | Select-Object -ExpandProperty Name
$SubDirs2 = Get-ChildItem -Path $Folder2 -Directory | Select-Object -ExpandProperty Name

# Compare the subdirectories
$Comparison = Compare-Object -ReferenceObject $SubDirs1 -DifferenceObject $SubDirs2

# Output the differences
if ($Comparison) {
    Write-Host "Differences between the subdirectories of '$Folder1' and '$Folder2':"
    foreach ($item in $Comparison) {
        if ($item.SideIndicator -eq '<=') {
            Write-Host " - '$($item.InputObject)' exists in '$Folder1' but not in '$Folder2'"
        } elseif ($item.SideIndicator -eq '=>') {
            Write-Host " - '$($item.InputObject)' exists in '$Folder2' but not in '$Folder1'"
        }
    }
} else {
    Write-Host "No differences found between the subdirectories of '$Folder1' and '$Folder2'."
}
