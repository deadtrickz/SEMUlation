# This script finds duplicate file names in a specified directory based on normalized names.

# Prompt user for the directory path
$Directory = Read-Host "Enter the path of the directory"

# Retrieve all files from the specified directory
$files = Get-ChildItem -Path $Directory -File

# Group files by a normalized base name, ignoring certain patterns and whitespace
$nameGroups = $files | Group-Object -Property {
    ($_.BaseName -replace '\[.*?\]|\(.*?\)|_|-01|-02|.ps3', '' -replace '\s+', ' ').Trim()
}

# Filter groups to find those with more than one file (duplicates)
$duplicates = $nameGroups | Where-Object { $_.Count -gt 1 }

# Output the results to the user
if ($duplicates) {
    Write-Host "Duplicate file names found:"
    foreach ($group in $duplicates) {
        Write-Host "Name: $($group.Name)"
        $group.Group | ForEach-Object { Write-Host " - $($_.Name)" }
    }
} else {
    Write-Host "No duplicate file names found."
}
Pause