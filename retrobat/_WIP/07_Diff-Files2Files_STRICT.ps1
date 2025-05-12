# This script compares the files in two directories and shows which files are unique to each directory.

# Prompt user for the paths of two directories to compare
$Directory1 = Read-Host "Enter the path of the first directory"
$Directory2 = Read-Host "Enter the path of the second directory"

# Retrieve file base names from both directories
$files1 = Get-ChildItem -Path $Directory1 -File | ForEach-Object { $_.BaseName }
$files2 = Get-ChildItem -Path $Directory2 -File | ForEach-Object { $_.BaseName }

# Compare the lists of files
$diff = Compare-Object -ReferenceObject $files1 -DifferenceObject $files2 -IncludeEqual -PassThru

# Identify files present in the first directory but missing in the second
$missingIn2 = $diff | Where-Object { $_.SideIndicator -eq '<=' }
# Identify files present in the second directory but missing in the first
$missingIn1 = $diff | Where-Object { $_.SideIndicator -eq '=>' }

# Display results
Write-Host "Files in ${Directory1} but not in ${Directory2}: $($missingIn2.Count)"
$missingIn2 | ForEach-Object { Write-Host "  $_" }

Write-Host "Files in ${Directory2} but not in ${Directory1}: $($missingIn1.Count)"
$missingIn1 | ForEach-Object { Write-Host "  $_" }

Pause