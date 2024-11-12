# This script copies video files from a video directory to a destination directory
# if their names match the names of ROM files in the ROM directory.

# Prompt user for directory paths
$RomsDirectory = Read-Host "Enter the path to the ROMs directory"
$VideoDirectory = Read-Host "Enter the path to the videos directory"
$DestinationDirectory = Read-Host "Enter the path to the destination videos directory"

# Create the destination directory if it does not exist
if (-not (Test-Path -Path $DestinationDirectory)) {
    New-Item -Path $DestinationDirectory -ItemType Directory | Out-Null
}

# Retrieve ROM filenames and video files
$RomFilenames = Get-ChildItem -Path $RomsDirectory -File | ForEach-Object { $_.BaseName }
$VideoFiles = Get-ChildItem -Path $VideoDirectory -File

# Initialize variables for counting
$totalFiles = $VideoFiles.Count
$filesCopied = 0

# Copy video files to destination if they match ROM filenames
foreach ($VideoFile in $VideoFiles) {
    if ($RomFilenames -contains $VideoFile.BaseName) {
        $DestinationFilePath = Join-Path -Path $DestinationDirectory -ChildPath $VideoFile.Name
        if (-not (Test-Path -Path $DestinationFilePath)) {
            Copy-Item -Path $VideoFile.FullName -Destination $DestinationFilePath
            $filesCopied++
            Write-Host "Copied $filesCopied/$totalFiles '$($VideoFile.Name)'"
        } else {
            Write-Host "Skipped '$($VideoFile.Name)' (already exists)"
        }
    }
}

# Final output message
Write-Host "Finished copying $filesCopied files."
Pause