# This script zips each folder in a specified directory individually, skipping folders that already have a corresponding zip file.

# Prompt user for the directory path where folders will be zipped
$DirectoryPath = Read-Host "Please enter the directory path to zip folders individually"

# Validate the directory path
while (-not (Test-Path -Path $DirectoryPath -PathType Container)) {
    Write-Host "The specified directory does not exist or is not valid."
    $DirectoryPath = Read-Host "Please enter a valid directory path to zip folders individually"
}

# Add necessary assembly for compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Retrieve all directories in the specified path
$folders = Get-ChildItem -Path $DirectoryPath -Directory
foreach ($folder in $folders) {
    $zipFilePath = Join-Path -Path $DirectoryPath -ChildPath ($folder.Name + ".zip")
    
    # Check if a zip file already exists to avoid overwriting
    if (-Not (Test-Path -Path $zipFilePath)) {
        try {
            # Create a zip file for each folder
            [System.IO.Compression.ZipFile]::CreateFromDirectory($folder.FullName, $zipFilePath, [System.IO.Compression.CompressionLevel]::Optimal, $false)
            Write-Host "Zipped $($folder.Name) to $($zipFilePath)"
        }
        catch {
            Write-Host "Failed to zip $($folder.Name): $_"
        }
    } else {
        Write-Host "Zip file already exists for $($folder.Name), skipping..."
    }
}
Pause