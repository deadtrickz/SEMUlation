[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$localRoot = Read-Host "Enter the path to the Local ROMs directory"
$remoteRoot = Read-Host "Enter the path to the Remote ROMs directory"
$subDirectories = @("3do", "ags", "amiga", "amiga1200", "amiga600", "amigacd32", "amstradcpc", "android", "apple2", "apple2gs", "arcade", "arcadia", "arduboy", "astrocde", "atari2600", "atari5200", "atari7800", "atari800", "atarijaguar", "atarijaguarcd", "atarilynx", "atarist", "atarixe", "atomiswave", "bbcmicro", "c16", "c64", "cavestory", "cdimono1", "cdtv", "chailove", "channelf", "cloud", "coco", "colecovision", "cps", "cps1", "cps2", "cps3", "crvision", "daphne", "desktop", "doom", "dos", "dragon32", "dreamcast", "easyrpg", "epic", "famicom", "fba", "fbneo", "fds", "flash", "fmtowns", "gameandwatch", "gamecom", "gamegear", "gb", "gba", "gbc", "gamecube", "gx4000", "intellivision", "j2me", "kodi", "lcdgames", "lutris", "lutro", "macintosh", "mame", "mame-advmame", "mame-mame4all", "mastersystem", "megacd", "megacdjp", "megadrive", "megadrivejp", "megaduck", "mess", "model2", "model3", "moonlight", "moto", "msx", "msx1", "msx2", "msxturbor", "mugen", "multivision", "n3ds", "n64", "n64dd", "naomi", "naomigd", "nds", "neogeo", "neogeocd", "neogeocdjp", "nes", "ngp", "ngpc", "odyssey2", "openbor", "oric", "palm", "pc", "pc88", "pc98", "pcengine", "pcenginecd", "pcfx", "pico8", "pokemini", "ports", "primehacks", "ps2", "ps3", "ps4", "psp", "psvita", "psx", "pv1000", "quake", "remoteplay", "samcoupe", "satellaview", "saturn", "saturnjp", "scummvm", "sega32x", "sega32xjp", "sega32xna", "segacd", "sfc", "sg-1000", "sgb", "snes", "sneshd", "snesna", "solarus", "spectravideo", "steam", "stratagus", "sufami", "supergrafx", "supervision", "switch", "symbian", "tanodragon", "tg-cd", "tg16", "ti99", "tic80", "to8", "trs-80", "uzebox", "vectrex", "vic20", "videopac", "virtualboy", "vsmile", "wasm4", "wii", "wiiu", "windows", "wonderswan", "wonderswancolor", "x1", "x68000", "xbox", "xbox360", "xbla", "zmachine", "zx81", "zxspectrum")
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
    Write-Host "Processing [$system]..."

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
        $missing = @()

        foreach ($type in $imageTypes) {
            $files = if (Test-Path -LiteralPath $remoteImages) { Get-ChildItem -LiteralPath $remoteImages -File } else { @() }
            $match = Find-MatchingFile $files $clean $type

            if ($match) {
                $dest = Join-Path $localImages "$rom-$type$($match.Extension)"
                if (!(Test-Path -LiteralPath $dest)) {
                    Copy-Item -LiteralPath $match.FullName -Destination $dest
                }
            } else {
                $missing += "-$type"
            }
        }

        $videoFiles = if (Test-Path -LiteralPath $remoteVideos) { Get-ChildItem -LiteralPath $remoteVideos -File } else { @() }
        $videoMatch = Find-MatchingFile $videoFiles $clean $videoType

        if ($videoMatch) {
            $videoDest = Join-Path $localVideos "$rom-$videoType$($videoMatch.Extension)"
            if (!(Test-Path -LiteralPath $videoDest)) {
                Copy-Item -LiteralPath $videoMatch.FullName -Destination $videoDest
            }
        } else {
            $missing += "-$videoType"
        }

        if ($missing.Count -gt 0) {
            if (-not $missingMedia.ContainsKey($system)) { $missingMedia[$system] = @{} }
            $missingMedia[$system][$rom] = $missing
        }
    }
}

# Only process systems present in local folder
foreach ($system in $subDirectories) {
    if (Test-Path -LiteralPath (Join-Path $localRoot $system)) {
        Update-System $system
    }
}

# Report
if ($missingMedia.Values | Where-Object { $_.Count -gt 0 }) {
    Write-Host "`n=== Missing Media Report ==="
    foreach ($system in $missingMedia.Keys) {
        if ($missingMedia[$system].Count -eq 0) { continue }
        Write-Host "[$system]"
        foreach ($rom in $missingMedia[$system].Keys) {
            $missing = $missingMedia[$system][$rom]
            if ($missing.Count -gt 0) {
                $types = ($missing | Sort-Object) -join ", "
                Write-Host "$rom ($types)"
            }
        }
        Write-Host ""
    }
} else {
    Write-Host "`nAll media present!"
}
Pause
