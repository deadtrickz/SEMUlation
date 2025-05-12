# Prompt for local and remote ROM directories
$LocalRomsDirectory = Read-Host "Enter the path to the LOCAL ROMs directory"
$RemoteRomsDirectory = Read-Host "Enter the path to the REMOTE ROMs directory (media source)"

# Define image folders and suffixes
$ImageFolders = @{
    "screenshots" = "-image"
    "marquees"    = "-marquee"
    "covers"      = "-thumb"
}

# Define video folder and suffix
$VideoFolder = "videos"
$VideoSuffix = "-video"

# Exact list of subdirectories (systems) to scan
$subDirectories = @(
    "3do", "ags", "amiga", "amiga1200", "amiga600", "amigacd32", "amstradcpc", "android", "apple2", "apple2gs",
    "arcade", "arcadia", "arduboy", "astrocde", "atari2600", "atari5200", "atari7800", "atari800", "atarijaguar",
    "atarijaguarcd", "atarilynx", "atarist", "atarixe", "atomiswave", "bbcmicro", "c16", "c64", "cavestory",
    "cdimono1", "cdtv", "chailove", "channelf", "cloud", "coco", "colecovision", "cps", "cps1", "cps2", "cps3",
    "crvision", "daphne", "desktop", "doom", "dos", "dragon32", "dreamcast", "easyrpg", "epic", "famicom", "fba",
    "fbneo", "fds", "flash", "fmtowns", "gameandwatch", "gamecom", "gamegear", "gb", "gba", "gbc", "gamecube",
    "gx4000", "intellivision", "j2me", "kodi", "lcdgames", "lutris", "lutro", "macintosh", "mame", "mame-advmame",
    "mame-mame4all", "mastersystem", "megacd", "megacdjp", "megadrive", "megadrivejp", "megaduck", "mess", "model2",
    "model3", "moonlight", "moto", "msx", "msx1", "msx2", "msxturbor", "mugen", "multivision", "n3ds", "n64", "n64dd",
    "naomi", "naomigd", "nds", "neogeo", "neogeocd", "neogeocdjp", "nes", "ngp", "ngpc", "odyssey2", "openbor",
    "oric", "palm", "pc", "pc88", "pc98", "pcengine", "pcenginecd", "pcfx", "pico8", "pokemini", "ports", "primehacks",
    "ps2", "ps3", "ps4", "psp", "psvita", "psx", "pv1000", "quake", "remoteplay", "samcoupe", "satellaview", "saturn",
    "saturnjp", "scummvm", "sega32x", "sega32xjp", "sega32xna", "segacd", "sfc", "sg-1000", "sgb", "snes", "sneshd",
    "snesna", "solarus", "spectravideo", "steam", "stratagus", "sufami", "supergrafx", "supervision", "switch",
    "symbian", "tanodragon", "tg-cd", "tg16", "ti99", "tic80", "to8", "trs-80", "uzebox", "vectrex", "vic20",
    "videopac", "virtualboy", "vsmile", "wasm4", "wii", "wiiu", "windows", "wonderswan", "wonderswancolor", "x1",
    "x68000", "xbox", "xbox360", "xbla", "zmachine", "zx81", "zxspectrum"
)

$filesCopied = 0
$missingReport = @{}

foreach ($system in $subDirectories) {
    $localSystemPath  = Join-Path $LocalRomsDirectory $system
    $remoteSystemPath = Join-Path $RemoteRomsDirectory $system

    if (-not (Test-Path $localSystemPath)) { continue }

    Write-Host "`nProcessing system: $system"

    $romEntries = Get-ChildItem -Path $localSystemPath -Force -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -notmatch '\.txt$' -and
        $_.PSIsContainer -and $_.Name -ne 'images' -and $_.Name -ne 'videos' -or
        -not $_.PSIsContainer -and $_.Name -notmatch '\.txt$'
    }

    $missingForSystem = @()

    foreach ($rom in $romEntries) {
        $romBase = $rom.BaseName
        $missingTypes = @()

        # --- VIDEO ---
        $remoteVideoPath = Join-Path $remoteSystemPath $VideoFolder
        $localVideoPath  = Join-Path $localSystemPath  $VideoFolder

        if (-not (Test-Path $localVideoPath)) {
            New-Item -Path $localVideoPath -ItemType Directory | Out-Null
        }

        if (Test-Path $remoteVideoPath) {
            $match = Get-ChildItem -Path $remoteVideoPath -File | Where-Object { $_.BaseName -eq $romBase }
            if ($match) {
                $dest = Join-Path $localVideoPath ($romBase + $VideoSuffix + $match.Extension)
                if (-not (Test-Path $dest)) {
                    Copy-Item -Path $match.FullName -Destination $dest
                    $filesCopied++
                    Write-Host "Copied video: $($match.Name)"
                }
            } else {
                $missingTypes += "-video"
            }
        } else {
            $missingTypes += "-video"
        }

        # --- IMAGES ---
        foreach ($folder in $ImageFolders.Keys) {
            $suffix = $ImageFolders[$folder]
            $remoteImagePath = Join-Path $remoteSystemPath $folder
            $localImagePath  = Join-Path $localSystemPath "images"

            if (-not (Test-Path $localImagePath)) {
                New-Item -Path $localImagePath -ItemType Directory | Out-Null
            }

            $foundMatch = $false
            if (Test-Path $remoteImagePath) {
                $remoteImages = Get-ChildItem $remoteImagePath -File
                foreach ($image in $remoteImages) {
                    $normImage = ($image.BaseName -replace '\[.*?\]|\(.*?\)|_|-01|-02|.ps3', '' -replace '\s+', ' ').Trim()
                    $normRom   = ($romBase -replace '\[.*?\]|\(.*?\)|_|-01|-02|.ps3', '' -replace '\s+', ' ').Trim()
                    if ($normRom -eq $normImage) {
                        $dest = Join-Path $localImagePath ($romBase + $suffix + $image.Extension)
                        if (-not (Test-Path $dest)) {
                            Copy-Item -Path $image.FullName -Destination $dest
                            $filesCopied++
                            Write-Host "Copied image: $($image.Name)"
                        }
                        $foundMatch = $true
                        break
                    }
                }
            }
            if (-not $foundMatch) {
                $missingTypes += $suffix
            }
        }

        if ($missingTypes.Count -gt 0) {
            $missingForSystem += "$romBase (missing $($missingTypes -join ", "))"
        }
    }

    if ($missingForSystem.Count -gt 0) {
        $missingReport[$system] = $missingForSystem
    }
}

# Output the report
foreach ($key in $missingReport.Keys) {
    Write-Host "`n[$($key.ToUpper())]"
    $missingReport[$key] | ForEach-Object { Write-Host $_ }
}

Write-Host "`nDone! Total files copied: $filesCopied"
Pause
