# This script compares folder names with file base names in two specified directories.

# Prompt user for the paths of the directories containing folders and files
$FoldersDirectory = Read-Host "Enter the path to the folders directory"
$FilesDirectory = Read-Host "Enter the path to the files directory"

# Retrieve folder names and file base names
$folderNames = Get-ChildItem -Path $FoldersDirectory -Directory | ForEach-Object { $_.Name }
$fileBases = Get-ChildItem -Path $FilesDirectory -File | ForEach-Object { $_.BaseName }

# Compare folder names with file base names
$diff = Compare-Object -ReferenceObject $folderNames -DifferenceObject $fileBases

# Display differences
if ($diff) {
    Write-Host "Differences found:"
    foreach ($item in $diff) {
        if ($item.SideIndicator -eq '<=') {
            Write-Host "Folder missing as file: $($item.InputObject)"
        } elseif ($item.SideIndicator -eq '=>') {
            Write-Host "File missing as folder: $($item.InputObject)"
        }
    }
} else {
    Write-Host "No differences found. All folders have matching files."
}

Pause