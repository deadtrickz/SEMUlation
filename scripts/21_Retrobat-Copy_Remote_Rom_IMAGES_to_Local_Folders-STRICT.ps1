# This script copies image files from specified folders in an image directory to a destination directory
# if their names match the names of ROM files in the ROM directory, appending "-image", "-marquee", or "-thumb" as appropriate.

# Prompt user for directory paths
$RomsDirectory = Read-Host "Enter the path to the ROMs directory"
$ImagesDirectory = Read-Host "Enter the path to the images directory"
$DestinationDirectory = Read-Host "Enter the path to the destination images directory"

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

# Retrieve ROM filenames (base names without extensions)
$RomFilenames = Get-ChildItem -Path $RomsDirectory -File | ForEach-Object { $_.BaseName }

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

    # Match and copy each image if it corresponds to a ROM file exactly
    foreach ($ImageFile in $ImageFiles) {
        if ($RomFilenames -contains $ImageFile.BaseName) {
            # Construct the destination path with the suffix and original extension
            $destinationFilePath = Join-Path -Path $DestinationDirectory -ChildPath ($ImageFile.BaseName + $suffix + $ImageFile.Extension)
            # Copy the file if it does not already exist in the destination
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

# Final output message
Write-Host "Finished copying $filesCopied files."
Pause