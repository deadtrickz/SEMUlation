# This script copies image files from a remote directory to a local directory,
# renaming them to match the names of ROM files with "-image", "-marquee", or "-thumb" appended in the destination.

# Prompt user for directory paths
$RomsDirectory = Read-Host "Enter the path to the ROMs directory"
$ImagesDirectory = Read-Host "Enter the path to the REMOTE images directory"
$DestinationDirectory = Read-Host "Enter the path to the LOCAL images directory"

# Define the image folders and their corresponding suffixes
$ImageFolders = @{
    "screenshots" = "-image"
    "marquees" = "-marquee"
    "covers" = "-thumb"
}

# Create the destination directory if it does not exist
if (-not (Test-Path -Path $DestinationDirectory)) {
    New-Item -Path $DestinationDirectory -ItemType Directory | Out-Null
}

# Get ROM files
$RomItems = Get-ChildItem -Path $RomsDirectory

# Initialize a counter for copied files
$filesCopied = 0

# Loop through each image folder and process files within
foreach ($folder in $ImageFolders.Keys) {
    # Define the suffix to append for files from this folder
    $suffix = $ImageFolders[$folder]
    # Get the path to the current image subfolder
    $currentImagePath = Join-Path -Path $ImagesDirectory -ChildPath $folder
    # Get all files in the current image folder
    $ImageFiles = Get-ChildItem -Path $currentImagePath -File

    # Copy and rename image files to match ROM names approximately
    foreach ($ImageFile in $ImageFiles) {
        $normalizedImageName = ($ImageFile.BaseName -replace '\[.*?\]|\(.*?\)|_|-01|-02|.ps3', '' -replace '\s+', ' ').Trim()
        foreach ($RomItem in $RomItems) {
            $normalizedRomName = ($RomItem.BaseName -replace '\[.*?\]|\(.*?\)|_|-01|-02|.ps3', '' -replace '\s+', ' ').Trim()
            if ($normalizedRomName -eq $normalizedImageName) {
                # Set destination filename with appropriate suffix
                $destinationFilePath = Join-Path -Path $DestinationDirectory -ChildPath ($RomItem.BaseName + $suffix + $ImageFile.Extension)
                if (-not (Test-Path -Path $destinationFilePath)) {
                    Copy-Item -Path $ImageFile.FullName -Destination $destinationFilePath
                    $filesCopied++
                    Write-Host "Copied '$($ImageFile.Name)' as '$($destinationFilePath)'"
                } else {
                    Write-Host "Skipped '$($ImageFile.Name)' (already exists in destination)"
                }
            }
        }
    }
}

# Final message to show operation is complete
Write-Host "Operation completed. Total files copied: $filesCopied"
Pause