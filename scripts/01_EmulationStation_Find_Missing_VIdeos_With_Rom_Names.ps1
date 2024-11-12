# This script checks for missing video files corresponding to ROMs in various subdirectories.

# Prompt user for directory paths
$RomsDirectory = Read-Host "Enter the path to the ROMs directory"
$DownloadedMediaDirectory = Read-Host "Enter the path to the downloaded_media directory"
$OutputToFile = Read-Host "Do you want to output missing videos to a text file? (Y/N)"

$subDirectories = @("3do", "ags", "amiga", "amiga1200", "amiga600", "amigacd32", "amstradcpc", "android", "apple2", "apple2gs", "arcade", "arcadia", "arduboy", "astrocde", "atari2600", "atari5200", "atari7800", "atari800", "atarijaguar", "atarijaguarcd", "atarilynx", "atarist", "atarixe", "atomiswave", "bbcmicro", "c16", "c64", "cavestory", "cdimono1", "cdtv", "chailove", "channelf", "cloud", "coco", "colecovision", "cps", "cps1", "cps2", "cps3", "crvision", "daphne", "desktop", "doom", "dos", "dragon32", "dreamcast", "easyrpg", "epic", "famicom", "fba", "fbneo", "fds", "flash", "fmtowns", "gameandwatch", "gamecom", "gamegear", "gb", "gba", "gbc", "gc", "genesis", "gx4000", "intellivision", "j2me", "kodi", "lcdgames", "lutris", "lutro", "macintosh", "mame", "mame-advmame", "mame-mame4all", "mastersystem", "megacd", "megacdjp", "megadrive", "megadrivejp", "megaduck", "mess", "model2", "model3", "moonlight", "moto", "msx", "msx1", "msx2", "msxturbor", "mugen", "multivision", "n3ds", "n64", "n64dd", "naomi", "naomigd", "nds", "neogeo", "neogeocd", "neogeocdjp", "nes", "ngp", "ngpc", "odyssey2", "openbor", "oric", "palm", "pc", "pc88", "pc98", "pcengine", "pcenginecd", "pcfx", "pico8", "pokemini", "ports", "primehacks", "ps2", "ps3", "ps4", "psp", "psvita", "psx", "pv1000", "quake", "remoteplay", "samcoupe", "satellaview", "saturn", "saturnjp", "scummvm", "sega32x", "sega32xjp", "sega32xna", "segacd", "sfc", "sg-1000", "sgb", "snes", "sneshd", "snesna", "solarus", "spectravideo", "steam", "stratagus", "sufami", "supergrafx", "supervision", "switch", "symbian", "tanodragon", "tg-cd", "tg16", "ti99", "tic80", "to8", "trs-80", "uzebox", "vectrex", "vic20", "videopac", "virtualboy", "vsmile", "wasm4", "wii", "wiiu\roms", "windows", "wonderswan", "wonderswancolor", "x1", "x68000", "xbox", "xbox360\roms", "xbox360\xbla", "zmachine", "zx81", "zxspectrum")

foreach ($subDir in $subDirectories) {
    $romSubDir = Join-Path -Path $RomsDirectory -ChildPath $subDir
    $mediaSubDir = $null
    if ($subDir -eq 'wiiu\roms') {
        $mediaSubDir = Join-Path -Path $DownloadedMediaDirectory -ChildPath "wiiu\videos\roms"
    } elseif ($subDir -match 'xbox360\\roms') {
        $mediaSubDir = Join-Path -Path $DownloadedMediaDirectory -ChildPath "xbox360\videos\roms"
    } elseif ($subDir -match 'xbox360\\xbla') {
        $mediaSubDir = Join-Path -Path $DownloadedMediaDirectory -ChildPath "xbox360\videos\xbla"
    } else {
        $mediaSubDir = Join-Path -Path $DownloadedMediaDirectory -ChildPath "$subDir\videos"
    }

    if ($mediaSubDir -and (Test-Path $romSubDir) -and (Test-Path $mediaSubDir)) {
        $outputPath = Join-Path -Path $mediaSubDir -ChildPath "_missing-videos.txt"
        if (Test-Path $outputPath) {
            Remove-Item $outputPath
        }

        $romFiles = Get-ChildItem -Path $romSubDir -File | Where-Object { $_.Extension -ne '.txt' -and $_.Extension -ne '.nfo' }
        $videoFiles = Get-ChildItem -Path $mediaSubDir -File | Where-Object { $_.Name -ne "_missing-videos.txt" }
        $uniqueRomNames = $romFiles.BaseName | Select-Object -Unique
        $videoNames = $videoFiles.BaseName | Select-Object -Unique

        $missingVideos = Compare-Object -ReferenceObject $uniqueRomNames -DifferenceObject $videoNames -PassThru

        if ($missingVideos.Count -gt 0) {
            Write-Host "$subDir is missing $($missingVideos.Count) videos."
            if ($OutputToFile -eq 'Y') {
                $missingVideos | ForEach-Object { $_ | Out-File -FilePath $outputPath -Append }
            }
        }
    }
}

Write-Host "Check complete."
Pause