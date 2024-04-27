# This script creates specific folders ('bios', 'images', 'videos') in the specified root path if they do not already exist.

# Define the root path where the folders will be created
$rootPath = "R:\"

# List of folders to check and create if missing
$foldersToCheck = @("bios", "images", "videos")

# Loop through each folder in the list to check their existence and create them if necessary
foreach ($folder in $foldersToCheck) {
    $folderPath = Join-Path -Path $rootPath -ChildPath $folder
    if (-not (Test-Path -Path $folderPath -PathType Container)) {
        New-Item -Path $folderPath -ItemType Directory | Out-Null
        Write-Host "'$folder' folder created successfully in $rootPath"
    } else {
        Write-Host "'$folder' folder already exists in $rootPath"
    }
}
Pause