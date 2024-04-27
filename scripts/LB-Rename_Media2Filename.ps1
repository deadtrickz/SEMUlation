# This script renames media files to match the names of ROM files in an emulation system directory,
# making them readable by Emulation Station.

# Prompt user for the necessary paths
$RomsDirectory = Read-Host "Enter the path to the ROMs directory"
$MediaDirectory = Read-Host "Enter the path to the media directory where renaming will occur"

# Check if subfolders should be included
$includeSubFolders = Read-Host "Do you want to include subfolders? (Y/N)"
$recurseOption = $false
if ($includeSubFolders -eq 'Y') {
    $recurseOption = $true
}

# Retrieve and normalize ROM names for comparison
$RomFiles = Get-ChildItem -Path $RomsDirectory -Recurse:$recurseOption -File
$RomNames = $RomFiles | ForEach-Object {
    $originalName = $_.BaseName
    # Inline normalization logic
    $normalized = $originalName -replace '_ ', ' - ' -replace '_', "'" `
                                 -replace ' (?=_)', " '" -replace '\[.*?\]|\(.*?\)|-0[1-9]|\.ps3', '' `
                                 -replace '\s+', ' '
    [PSCustomObject]@{
        OriginalName = $originalName
        NormalizedName = $normalized.Trim()
    }
}

$lastDirectory = $null # Variable to store the last processed directory

# Retrieve and process media files
$mediaFiles = Get-ChildItem -Path $MediaDirectory -File -Recurse:$recurseOption
foreach ($file in $mediaFiles) {
    $currentDirectory = $file.DirectoryName

    # Only print and update lastDirectory if the current directory has changed
    if ($currentDirectory -ne $lastDirectory) {
        Write-Host "Processing Directory: $currentDirectory" -ForegroundColor Yellow
        $lastDirectory = $currentDirectory # Update the lastDirectory variable
    }

    # Normalize media file name
    $normalizedMediaName = $file.BaseName -replace '_ ', ' - ' `
                                          -replace '(_(?=\d))|(_(?=[a-zA-Z]))', "'" `
                                          -replace '_', ' ' `
                                          -replace '\[.*?\]|\(.*?\)|-0[1-9]|\.ps3', '' `
                                          -replace '\s+', ' '

    # Find a matching ROM name
    $matchedRom = $RomNames | Where-Object { $_.NormalizedName -eq $normalizedMediaName }

    if ($matchedRom) {
        $newFileName = "$($matchedRom.OriginalName)$($file.Extension)"
        $newFilePath = Join-Path -Path $currentDirectory -ChildPath $newFileName

        if (-not (Test-Path -Path $newFilePath)) {
            Rename-Item -Path $file.FullName -NewName $newFilePath
            Write-Host "Renamed '$($file.Name)' to '$newFileName'" -ForegroundColor Green
        } else {
            Write-Host "Skipping '$($file.Name)', new file name already exists." -ForegroundColor Red
        }
    } else {
        Write-Host "No matching ROM found for '$($file.Name)'. Normalized as '$normalizedMediaName'" -ForegroundColor Red
    }
}

Write-Host "Renaming process complete."
Pause