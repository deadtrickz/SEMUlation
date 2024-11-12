# This script zips each file in a specified directory individually, skipping files that are already compressed.

# Prompt user for directory path
$DirectoryPath = Read-Host "Please enter the directory path to zip files individually"

# Validate the directory path
while (-not (Test-Path -Path $DirectoryPath -PathType Container)) {
    Write-Host "The specified directory does not exist or is not valid."
    $DirectoryPath = Read-Host "Please enter a valid directory path to zip files individually"
}

# Add necessary assemblies for compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression

# Define file extensions to exclude from zipping
$compressedFileExtensions = @('.zip', '.rar', '.7z', '.tar', '.gz', '.txt')

# Retrieve files that are not already compressed
$files = Get-ChildItem -Path $DirectoryPath -File | Where-Object { $compressedFileExtensions -notcontains $_.Extension.ToLower() }
foreach ($file in $files) {
    $zipFilePath = Join-Path -Path $DirectoryPath -ChildPath ($file.BaseName + ".zip")
    
    # Check if zip file already exists to avoid overwriting
    if (-Not (Test-Path -Path $zipFilePath)) {
        try {
            # Create a new zip archive for each file
            $zip = [System.IO.Compression.ZipFile]::Open($zipFilePath, [System.IO.Compression.ZipArchiveMode]::Create)
            $zipEntry = $zip.CreateEntry($file.Name, [System.IO.Compression.CompressionLevel]::Optimal)
            $fileStream = [System.IO.File]::OpenRead($file.FullName)
            $entryStream = $zipEntry.Open()
            
            # Copy the file into the zip archive
            $fileStream.CopyTo($entryStream)
            $entryStream.Close()
            $fileStream.Close()
            $zip.Dispose()

            Write-Host "Zipped $($file.Name) to $($zipFilePath)"
        }
        catch {
            Write-Host "Failed to zip $($file.Name): $_"
        }
    } else {
        Write-Host "Zip file already exists for $($file.Name), skipping..."
    }
}
Pause