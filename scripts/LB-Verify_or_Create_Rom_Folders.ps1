# This script checks for the existence of specified folders within a directory and offers to copy missing ones from a default location.

# Set default path and known folder names for Launchbox
$defaultFolderPath = "R:\Launchbox\Games"
$launchboxFolders = @("3DO Interactive Multiplayer", "AAE", "American Laser Games", "Amstrad CPC", "Amstrad GX4000", "Apple II", "Arcade", "Atari 2600", "Atari 5200", "Atari 7800", "Atari Jaguar", "Atari Jaguar CD", "Atari Lynx", "BBC Microcomputer System", "Capcom Play System", "Capcom Play System II", "Capcom Play System III", "Cave", "Clone Hero", "ColecoVision", "Commodore 64", "Commodore Amiga", "Commodore Amiga CD32", "Commodore CDTV", "Commodore VIC-20", "Creatronic Mega Duck", "Daphne", "Doujin Games", "Emerson Arcadia 2001", "Entex Adventure Vision", "Epoch Super Cassette Vision", "Examu Ex-Board", "Fairchild Channel F", "Fruit Machines", "GCE Vectrex", "GOG", "HB MAME", "Konami Handheld", "Magnavox Odyssey 2", "Mattel Intellivision", "Microsoft Xbox", "Microsoft Xbox 360", "MSU MD+", "MUGEN", "NEC PC Engine", "NEC PC-FX", "NEC TurboGrafx-16", "NEC TurboGrafx-CD", "Nintendo 3DS", "Nintendo 64", "Nintendo 64 HD", "Nintendo DS", "Nintendo Entertainment System", "Nintendo Entertainment System HD", "Nintendo Famicom Disk System", "Nintendo Game & Watch", "Nintendo Game Boy", "Nintendo Game Boy Advance", "Nintendo Game Boy Color", "Nintendo GameCube", "Nintendo Switch", "Nintendo Virtual Boy", "Nintendo Wii", "Nintendo Wii U", "Nokia N-Gage", "OpenBOR", "PC Engine SuperGrafx", "Philips CD-i", "Pinball Arcade", "Pinball FX2", "Pinball FX3", "Platform Categories", "Platforms", "Playlists", "PopCap", "Quiz Machines", "Recordings", "Sammy Atomiswave", "ScummVM", "Sega 32X", "Sega CD", "Sega CD 32X", "Sega Dreamcast", "Sega Game Gear", "Sega Genesis", "Sega Master System", "Sega Model 1", "Sega Model 2", "Sega Model 3", "Sega Naomi", "Sega Saturn", "Sega SG-1000", "Sega ST-V", "Sega System 16", "Sega System 24", "Sega System 32", "Sega Triforce", "Sega X Board", "Sega Y Board", "Sinclair ZX Spectrum", "Singe 2", "SNK Neo Geo AES", "SNK Neo Geo CD", "SNK Neo Geo Pocket", "SNK Neo Geo Pocket Color", "Sony Playstation", "Sony Playstation 2", "Sony Playstation 3", "Sony Playstation Vita", "Sony PSP", "Super Nintendo Entertainment System", "Super Nintendo MSU-1", "Taito NESiCAxLive", "Taito Type X", "Tekno Parrot", "Theme", "Tiger Game.com", "Tiger Handheld", "Trailer", "Videos", "Windows", "WonderSwan", "WonderSwan Color", "WoW Action Max", "ZiNc")

# User option to use default path or provide a new one
$userInput = Read-Host "Do you want to use default folders to check? (Y/N)"

if ($userInput -eq 'Y' -or $userInput -eq 'y') {
    $folderPath = $defaultFolderPath
} else {
    $folderPath = Read-Host "Enter the folder path to check"
}

# Check for existence of folders and identify missing ones
$missingFolders = @()
foreach ($folder in $launchboxFolders) {
    $subFolderPath = Join-Path -Path $folderPath -ChildPath $folder
    if (-not (Test-Path -Path $subFolderPath -PathType Container)) {
        $missingFolders += $folder
    }
}

# Report missing folders and offer to copy them from a development path
if ($missingFolders.Count -gt 0) {
    Write-Host "The following folders are missing in ${folderPath}:"
    $missingFolders | ForEach-Object { Write-Host " - $_" }
    $copy = Read-Host "Do you want to copy missing folders from _dev\Launchbox\Games? (Y/N)"
    if ($copy -match '^[Yy]') {
        $sourcePath = Join-Path -Path $PSScriptRoot -ChildPath "_dev\Launchbox\Games"
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