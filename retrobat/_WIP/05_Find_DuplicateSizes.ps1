# This script identifies duplicate file sizes within a specified directory and lists the files sharing the same size.

# Prompt user for the directory path
$Directory = Read-Host "Enter the path of the directory"

# Retrieve all files from the specified directory
$files = Get-ChildItem -Path $Directory -File

# Group files by their size
$sizeGroups = $files | Group-Object -Property Length

# Filter groups to identify those with more than one file having the same size
$duplicates = $sizeGroups | Where-Object { $_.Count -gt 1 }

# Output the results to the user
if ($duplicates) {
    Write-Host "Duplicate file sizes found:"
    foreach ($group in $duplicates) {
        Write-Host "Size: $($group.Name) bytes"
        $group.Group | ForEach-Object { Write-Host " - $($_.Name)" }
    }
} else {
    Write-Host "No duplicate file sizes found."
}
Pause