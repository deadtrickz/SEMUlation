# This script copies video files from a remote directory to a local directory,
# renaming them to match the names of ROM files.

# Prompt user for directory paths
$RomsDirectory = Read-Host "Enter the path to the ROMs directory"
$VideoDirectory = Read-Host "Enter the path to the REMOTE video directory"
$DestinationDirectory = Read-Host "Enter the path to the LOCAL videos directory"

# Create the destination directory if it does not exist
if (-not (Test-Path -Path $DestinationDirectory)) {
    New-Item -Path $DestinationDirectory -ItemType Directory | Out-Null
}

# Get ROM and video files
$RomItems = Get-ChildItem -Path $RomsDirectory
$VideoFiles = Get-ChildItem -Path $VideoDirectory -File | Sort-Object Name

# Initialize a counter for copied files
$totalFiles = $VideoFiles.Count
$filesCopied = 0

# Copy and rename video files to match ROM names
foreach ($VideoFile in $VideoFiles) {
    $normalizedVideoName = ($VideoFile.BaseName -replace '\[.*?\]|\(.*?\)|_|-01|-02|.ps3', '' -replace '\s+', ' ').Trim()
    foreach ($RomItem in $RomItems) {
        $normalizedRomName = ($RomItem.BaseName -replace '\[.*?\]|\(.*?\)|_|-01|-02|.ps3', '' -replace '\s+', ' ').Trim()
        if ($normalizedRomName -eq $normalizedVideoName) {
            $destinationFilePath = Join-Path -Path $DestinationDirectory -ChildPath ($RomItem.BaseName + $VideoFile.Extension)
            if (-not (Test-Path -Path $destinationFilePath)) {
                Copy-Item -Path $VideoFile.FullName -Destination $destinationFilePath
                $filesCopied++
                Write-Host "Copied and renamed $filesCopied/$totalFiles '$($VideoFile.Name)' to match '$($RomItem.Name)'"
            } else {
                Write-Host "Skipped '$($VideoFile.Name)' (already exists)"
            }
        }
    }
}

# Final message to show operation is complete
Write-Host "Operation completed. Total files copied: $filesCopied"
Pause