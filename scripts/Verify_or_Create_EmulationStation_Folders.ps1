# This script checks for the existence of predefined folders within a directory and offers to copy missing ones from a default backup location.

# Define default path and folder names
$defaultFolderPath = "R:\roms"
$defaultFolders = @("3do", "ags", "amiga", "amiga1200", "amiga600", "amigacd32", "amstradcpc", "android", "apple2", "apple2gs", "arcade", "arcadia", "arduboy", "astrocde", "atari2600", "atari5200", "atari7800", "atari800", "atarijaguar", "atarijaguarcd", "atarilynx", "atarist", "atarixe", "atomiswave", "bbcmicro", "c16", "c64", "cavestory", "cdimono1", "cdtv", "chailove", "channelf", "cloud", "coco", "colecovision", "cps", "cps1", "cps2", "cps3", "crvision", "daphne", "desktop", "doom", "dos", "dragon32", "dreamcast", "easyrpg", "epic", "famicom", "fba", "fbneo", "fds", "flash", "fmtowns", "gameandwatch", "gamecom", "gamegear", "gb", "gba", "gbc", "gc", "genesis", "genesiswide", "gx4000", "intellivision", "j2me", "kodi", "lcdgames", "lutris", "lutro", "macintosh", "mame-advmame", "mame-mame4all", "mame", "mastersystem", "megacd", "megacdjp", "megadrive", "megadrivejp", "megaduck", "mess", "model2", "model3", "moonlight", "moto", "msx", "msx1", "msx2", "msxturbor", "mugen", "multivision", "n3ds", "n64", "n64dd", "naomi", "naomi2", "naomigd", "nds", "neogeo", "neogeocd", "neogeocdjp", "nes", "ngp", "ngpc", "odyssey2", "openbor", "oric", "palm", "pc", "pc88", "pc98", "pcengine", "pcenginecd", "pcfx", "pico8", "pokemini", "ports", "primehacks", "ps2", "ps3", "ps4", "psp", "psvita", "psx", "pv1000", "quake", "remoteplay", "samcoupe", "satellaview", "saturn", "saturnjp", "scummvm", "sega32x", "sega32xjp", "sega32xna", "segacd", "sfc", "sg-1000", "sgb", "snes", "sneshd", "snesna", "solarus", "spectravideo", "steam", "stratagus", "sufami", "supergrafx", "supervision", "switch", "symbian", "tanodragon", "tg-cd", "tg16", "ti99", "tic80", "to8", "trs-80", "uzebox", "vectrex", "vic20", "videopac", "virtualboy", "vsmile", "wasm4", "wii", "wiiu/roms", "wonderswan", "wonderswancolor", "x1", "x68000", "xbox", "xbox360", "zmachine", "zx81", "zxspectrum")

# User interaction to choose default path or custom path
$userInput = Read-Host "Do you want to use default folders to check? (Y/N)"

if ($userInput -eq 'Y' -or $userInput -eq 'y') {
    $folderPath = $defaultFolderPath
    $foldersToCheck = $defaultFolders
} else {
    $folderPath = Read-Host "Enter the folder path to check"
    $foldersToCheck = $defaultFolders
}

# Check for the existence of folders and report missing ones
$missingFolders = @()
foreach ($folder in $foldersToCheck) {
    $subFolderPath = Join-Path -Path $folderPath -ChildPath $folder
    if (-not (Test-Path -Path $subFolderPath -PathType Container)) {
        $missingFolders += $folder
    }
}

# Offer to copy missing folders from a development backup
if ($missingFolders.Count -gt 0) {
    Write-Host "The following folders are missing in ${folderPath}:"
    $missingFolders | ForEach-Object { Write-Host " - $_" }
    $copy = Read-Host "Do you want to copy missing folders from _dev/roms? (Y/N)"
    if ($copy -match '^[Yy]') {
        $sourcePath = Join-Path -Path $PSScriptRoot -ChildPath "_dev\roms"
        Write-Host "Copying missing folders to '$folderPath'..."
        foreach ($missingFolder in $missingFolders) {
            $sourceFolder = Join-Path -Path $sourcePath -ChildPath $missingFolder
            $destinationFolder = Join-Path -Path $folderPath -ChildPath $missingFolder
            Copy-Item -Path $sourceFolder -Destination $destinationFolder -Recurse -Force
        }
        Write-Host "Missing folders were successfully copied."
    } else {
        Write-Host "Operation aborted. No folders copied."
    }
} else {
    Write-Host "All required folders exist in $folderPath."
}
Pause