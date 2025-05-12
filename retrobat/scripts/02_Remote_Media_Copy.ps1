[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$localRoot = Read-Host "Enter the path to the Local ROMs directory"
$remoteRoot = Read-Host "Enter the path to the Remote ROMs directory"
$subDirectories = @("megadrive", "snes", "nes", "switch") # Adjust as needed
$imageTypes = @('image', 'marquee', 'thumb')
$videoType = 'video'
$missingMedia = @{}

function Get-CleanName {
    param ($name)
    return $name -replace '\s+', ' ' `
                 -replace '\[[^\]]*\]', '' `
                 -replace '\([^\)]*\)', '' `
                 -replace '[-_](0[1-9]|[1-9][0-9])$', '' `
                 -replace '\.ps3$', '' `
                 -replace '[^a-zA-Z0-9 ]', '' `
                 -replace '\s+', ' ' `
                 -replace '^\s+|\s+$', ''
}

function Get-RomDict {
    param ($romFiles)
    $dict = @{}
    foreach ($rom in $romFiles) {
        $base = if ($rom.PSIsContainer) { $rom.Name } else { [System.IO.Path]::GetFileNameWithoutExtension($rom.Name) }
        $dict[$base] = Get-CleanName $base
    }
    return $dict
}

function Find-MatchingFile {
    param ($files, $cleanRomName, $suffix)
    return $files | Where-Object { ($_.BaseName -match "-$suffix$") -and (Get-CleanName ($_.BaseName -replace "-$suffix$", "")) -eq $cleanRomName }
}

function Test-Folder {
    param ($path)
    if (!(Test-Path -LiteralPath $path)) { New-Item -ItemType Directory -Force -Path $path | Out-Null }
}

function Update-System {
    param ($system)
    $localPath = Join-Path $localRoot $system
    $remotePath = Join-Path $remoteRoot $system

    if (!(Test-Path -LiteralPath $localPath) -or !(Test-Path -LiteralPath $remotePath)) { return }

    $localImages = Join-Path $localPath "images"
    $remoteImages = Join-Path $remotePath "images"
    $localVideos = Join-Path $localPath "videos"
    $remoteVideos = Join-Path $remotePath "videos"

    Test-Folder $localImages
    Test-Folder $localVideos

    $romFiles = Get-ChildItem -LiteralPath $localPath | Where-Object { !$_.PSIsContainer -or $_.Extension -eq ".ps3" }
    $romDict = Get-RomDict $romFiles

    foreach ($rom in $romDict.Keys) {
        $clean = $romDict[$rom]

        foreach ($type in $imageTypes) {
            $files = if (Test-Path -LiteralPath $remoteImages) { Get-ChildItem -LiteralPath $remoteImages -File } else { @() }
            $match = Find-MatchingFile $files $clean $type

            if ($match) {
                $dest = Join-Path $localImages "$rom-$type$($match.Extension)"
                if (!(Test-Path -LiteralPath $dest)) { Copy-Item -LiteralPath $match.FullName -Destination $dest }
            } else {
                $missingMedia[$system][$rom] += "-$type"
            }
        }

        $videoFiles = if (Test-Path -LiteralPath $remoteVideos) { Get-ChildItem -LiteralPath $remoteVideos -File } else { @() }
        $videoMatch = Find-MatchingFile $videoFiles $clean $videoType

        if ($videoMatch) {
            $videoDest = Join-Path $localVideos "$rom-$videoType$($videoMatch.Extension)"
            if (!(Test-Path -LiteralPath $videoDest)) { Copy-Item -LiteralPath $videoMatch.FullName -Destination $videoDest }
        } else {
            $missingMedia[$system][$rom] += "-$videoType"
        }
    }
}

foreach ($system in $subDirectories) {
    if (-not $missingMedia.ContainsKey($system)) { $missingMedia[$system] = @{} }
    Update-System $system
}

# Report
if ($missingMedia.Values | Where-Object { $_.Count -gt 0 }) {
    Write-Host "`n=== Missing Media Report ==="
    foreach ($system in $missingMedia.Keys) {
        if ($missingMedia[$system].Count -eq 0) { continue }
        Write-Host "[$system]"
        foreach ($rom in $missingMedia[$system].Keys) {
            $types = ($missingMedia[$system][$rom] | Sort-Object) -join ", "
            Write-Host "$rom ($types)"
        }
        Write-Host ""
    }
} else {
    Write-Host "`nAll media present!"
}
Pause
