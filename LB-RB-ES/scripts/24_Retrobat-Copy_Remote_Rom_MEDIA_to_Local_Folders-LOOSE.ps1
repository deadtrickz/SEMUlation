# This script copies media files (images and videos) from a remote media directory to local "images" and "videos" directories
# under $RomsDirectory, renaming files to match the names of ROM files with specific suffixes.

# Prompt user for directory paths
$RomsDirectory = Read-Host "Enter the path to the ROMs directory"
$MediaDirectory = Read-Host "Enter the path to the REMOTE media directory"

# Define image folders and their corresponding suffixes
$ImageFolders = @{
    "screenshots" = "-image"
    "marquees" = "-marquee"
    "covers" = "-thumb"
}

# Define the video folder and suffix
$VideoFolder = "videos"
$VideoSuffix = "-video"

# Set destination directories for images and videos within $RomsDirectory
$DestinationImagesDirectory = Join-Path -Path $RomsDirectory -ChildPath "images"
$DestinationVideosDirectory = Join-Path -Path $RomsDirectory -ChildPath "videos"

# Create destination directories if they do not exist
if (-not (Test-Path -Path $DestinationImagesDirectory)) {
    New-Item -Path $DestinationImagesDirectory -ItemType Directory | Out-Null
}
if (-not (Test-Path -Path $DestinationVideosDirectory)) {
    New-Item -Path $DestinationVideosDirectory -ItemType Directory | Out-Null
}

# Get ROM files
$RomItems = Get-ChildItem -Path $RomsDirectory

# Initialize a counter for copied files
$filesCopied = 0

# Function to check if a file with the same base name exists in destination
function FileExistsWithBaseName ($destinationPath, $baseName) {
    $existingFiles = Get-ChildItem -Path $destinationPath -Filter "$baseName.*" -File -ErrorAction SilentlyContinue
    return $existingFiles.Count -gt 0
}

# Process image files from each folder in $ImageFolders
foreach ($folder in $ImageFolders.Keys) {
    # Define the suffix to append for files from this folder
    $suffix = $ImageFolders[$folder]
    # Get the path to the current image subfolder in $MediaDirectory
    $currentImagePath = Join-Path -Path $MediaDirectory -ChildPath $folder
    # Get all files in the current image folder
    $ImageFiles = Get-ChildItem -Path $currentImagePath -File -ErrorAction SilentlyContinue

    if ($ImageFiles) {
        # Copy and rename image files to match ROM names approximately
        foreach ($ImageFile in $ImageFiles) {
            $normalizedImageName = ($ImageFile.BaseName -replace '\[.*?\]|\(.*?\)|_|-01|-02|.ps3', '' -replace '\s+', ' ').Trim()
            foreach ($RomItem in $RomItems) {
                $normalizedRomName = ($RomItem.BaseName -replace '\[.*?\]|\(.*?\)|_|-01|-02|.ps3', '' -replace '\s+', ' ').Trim()
                if ($normalizedRomName -eq $normalizedImageName) {
                    # Set destination filename with the appropriate suffix
                    $destinationFilePath = Join-Path -Path $DestinationImagesDirectory -ChildPath ($RomItem.BaseName + $suffix + $ImageFile.Extension)
                    if (-not (FileExistsWithBaseName -destinationPath $DestinationImagesDirectory -baseName $RomItem.BaseName)) {
                        Copy-Item -Path $ImageFile.FullName -Destination $destinationFilePath
                        $filesCopied++
                        Write-Host "Copied '$($ImageFile.Name)' as '$($destinationFilePath)'"
                    } else {
                        Write-Host "Skipped '$($ImageFile.Name)' (matching base name already exists in destination)"
                    }
                }
            }
        }
    }
}

# Process video files from the videos folder
$VideoFilesPath = Join-Path -Path $MediaDirectory -ChildPath $VideoFolder
$VideoFiles = Get-ChildItem -Path $VideoFilesPath -File -ErrorAction SilentlyContinue

if ($VideoFiles) {
    foreach ($RomItem in $RomItems) {
        $matchingVideo = $VideoFiles | Where-Object { $_.BaseName -eq $RomItem.BaseName }
        if ($matchingVideo) {
            # Set destination filename with "-video" appended
            $destinationFilePath = Join-Path -Path $DestinationVideosDirectory -ChildPath ($RomItem.BaseName + $VideoSuffix + $matchingVideo.Extension)
            if (-not (FileExistsWithBaseName -destinationPath $DestinationVideosDirectory -baseName $RomItem.BaseName)) {
                Copy-Item -Path $matchingVideo.FullName -Destination $destinationFilePath
                $filesCopied++
                Write-Host "Copied '$($matchingVideo.Name)' as '$($destinationFilePath)'"
            } else {
                Write-Host "Skipped '$($matchingVideo.Name)' (matching base name already exists in destination)"
            }
        }
    }
}

# Final message to show operation is complete
Write-Host "Operation completed. Total files copied: $filesCopied"
Pause
