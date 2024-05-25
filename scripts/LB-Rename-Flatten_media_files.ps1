# This script renames and flattens all media files in a specified directory,
# organizing them into a common directory structure suitable for Launchbox to Emulation Station conversion.

# Prompt user for the necessary path
$MediaDirectory = Read-Host "Enter the path to the media directory where renaming and flattening will occur"

# Define known folders for different types of media
$knownFolders = @(
    "Advertisement Flyer - Back", "Advertisement Flyer - Front", "Amazon Background", "Amazon Poster", "Amazon Screenshot",
    "Arcade - Cabinet", "Arcade - Circuit Board", "Arcade - Control Panel", "Arcade - Controls Information", "Arcade - Marquee",
    "Banner", "Box - 3D", "Box - Back", "Box - Back - Reconstructed", "Box - Front", "Box - Front - Reconstructed",
    "Box - Full", "Box - Spine", "Cart - 3D", "Cart - Back", "Cart - Front", "Clear Logo", "Disc",
    "Epic Games Background", "Epic Games Poster", "Epic Games Screenshot", "Fanart - Background", "Fanart - Box - Back",
    "Fanart - Box - Front", "Fanart - Cart - Back", "Fanart - Cart - Front", "Fanart - Disc", "GOG Poster", "GOG Screenshot",
    "Origin Background", "Origin Poster", "Origin Screenshot", "Screenshot - Game Over", "Screenshot - Game Select",
    "Screenshot - Game Title", "Screenshot - Gameplay", "Screenshot - High Scores", "Steam Banner", "Steam Poster",
    "Steam Screenshot", "Uplay Background", "Uplay Thumbnail", "*"
)

$lastDirectory = $null # Variable to store the last processed directory

# Process each known folder and normalize, rename, and move files accordingly
foreach ($folder in $knownFolders) {
    $folderPath = Join-Path -Path $MediaDirectory -ChildPath $folder
    if (Test-Path $folderPath) {
        $allFiles = Get-ChildItem -Path $folderPath -Recurse -File
        foreach ($file in $allFiles) {
            $currentDirectory = $file.DirectoryName

            # Only print and update lastDirectory if the current directory has changed
            if ($currentDirectory -ne $lastDirectory) {
                Write-Host "Processing Directory: $currentDirectory" -ForegroundColor Yellow
                $lastDirectory = $currentDirectory
            }

            # Normalize media file name
            $normalizedMediaName = $file.BaseName -replace '_ ', ' - ' `
                                                -replace '(_(?=\d))|(_(?=[a-zA-Z]))', "'" `
                                                -replace '_', ' ' `
                                                -replace '\[.*?\]|\(.*?\)|-0[1-9]|\.ps3', '' `
                                                -replace '\s+', ' '

            $newFileName = "$normalizedMediaName$($file.Extension)"
            $newFilePath = Join-Path -Path $folderPath -ChildPath $newFileName

            if (-not (Test-Path -Path $newFilePath)) {
                Move-Item -Path $file.FullName -Destination $newFilePath
                Write-Host "Renaming and moving '$($file.Name)' to '$newFilePath'" -ForegroundColor Green
            } else {
                Write-Host "Skipping '$($file.Name)', target file already exists." -ForegroundColor Red
            }
        }
    }
}
Write-Host "Media processing complete."
Pause
