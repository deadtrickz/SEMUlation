function Show-Menu {
    Clear-Host
    Write-Host @"
    
><><><><><><><><><><
SEMUlator Rom Tools
~ ~~~~ V0.89 ~~~~~ ~
by Deadtrickz
><><><><><><><><><><

"@ -ForegroundColor Yellow
    Write-Host "1: Verify or Create Rom Folders In R:\roms"
    Write-Host "2: Check/Create 'bios', 'images', and 'videos' folders in R:\"
    Write-Host "3: Copy Rom Videos From Remote Folder To Local Folder - STRICT"
    Write-Host "4: Copy Rom Videos From Remote Folder To Local Folder - IGNORE DESIGNATIONS - READS FOLDER NAMES ALSO"
    Write-Host "5: Run A Diff On 2 folders"
    Write-Host "6: Run A Diff On 2 Folders - Use Folders as filenames"
    Write-Host "96: Verify or Create Launchbox Rom Folders In R:\Launchbox\Games"
    Write-Host "97: Zip Each File Individually In A Specified Directory"
    Write-Host "98: Find Duplicate Filenames In A Folder"
    Write-Host "99: Find Duplicate File Sizes In A Folder"
    Write-Host "Q: Quit"
}

# OPTION 1
function Test-FoldersExist {
    $defaultFolderPath = "R:\roms"

    $defaultFolders = @("3do", "ags", "amiga", "amiga1200", "amiga600", "amigacd32", "amstradcpc", "android", "apple2", "apple2gs", "arcade", "arcadia", "arduboy", "astrocde", "atari2600", "atari5200", "atari7800", "atari800", "atarijaguar", "atarijaguarcd", "atarilynx", "atarist", "atarixe", "atomiswave", "bbcmicro", "c16", "c64", "cavestory", "cdimono1", "cdtv", "chailove", "channelf", "cloud", "coco", "colecovision", "cps", "cps1", "cps2", "cps3", "crvision", "daphne", "desktop", "doom", "dos", "dragon32", "dreamcast", "easyrpg", "epic", "famicom", "fba", "fbneo", "fds", "flash", "fmtowns", "gameandwatch", "gamecom", "gamegear", "gb", "gba", "gbc", "gc", "genesis", "genesiswide", "gx4000", "intellivision", "j2me", "kodi", "lcdgames", "lutris", "lutro", "macintosh", "mame-advmame", "mame-mame4all", "mame", "mastersystem", "megacd", "megacdjp", "megadrive", "megadrivejp", "megaduck", "mess", "model2", "model3", "moonlight", "moto", "msx", "msx1", "msx2", "msxturbor", "mugen", "multivision", "n3ds", "n64", "n64dd", "naomi", "naomi2", "naomigd", "nds", "neogeo", "neogeocd", "neogeocdjp", "nes", "ngp", "ngpc", "odyssey2", "openbor", "oric", "palm", "pc", "pc88", "pc98", "pcengine", "pcenginecd", "pcfx", "pico8", "pokemini", "ports", "primehacks", "ps2", "ps3", "ps4", "psp", "psvita", "psx", "pv1000", "quake", "remoteplay", "samcoupe", "satellaview", "saturn", "saturnjp", "scummvm", "sega32x", "sega32xjp", "sega32xna", "segacd", "sfc", "sg-1000", "sgb", "snes", "sneshd", "snesna", "solarus", "spectravideo", "steam", "stratagus", "sufami", "supergrafx", "supervision", "switch", "symbian", "tanodragon", "tg-cd", "tg16", "ti99", "tic80", "to8", "trs-80", "uzebox", "vectrex", "vic20", "videopac", "virtualboy", "vsmile", "wasm4", "wii", "wiiu/roms", "wonderswan", "wonderswancolor", "x1", "x68000", "xbox", "xbox360", "zmachine", "zx81", "zxspectrum")

    $userInput = Read-Host "Do you want to use default folders to check? (Y/N)"
    
    if ($userInput -eq 'Y' -or $userInput -eq 'y') {
        $folderPath = $defaultFolderPath
        $foldersToCheck = $defaultFolders
    } else {
        $folderPath = Read-Host "Enter the folder path to check"
        $foldersToCheck = $defaultFolders
    }

    $missingFolders = @()
    foreach ($folder in $foldersToCheck) {
        $subFolderPath = Join-Path -Path $folderPath -ChildPath $folder
        if (-not (Test-Path -Path $subFolderPath -PathType Container)) {
            $missingFolders += $folder
        }
    }

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
}

# OPTION 2
function Initialize-BiosImagesVideosFolders {
    $rootPath = "R:\"
    $foldersToCheck = @("bios", "images", "videos")

    foreach ($folder in $foldersToCheck) {
        $folderPath = Join-Path -Path $rootPath -ChildPath $folder
        if (-not (Test-Path -Path $folderPath -PathType Container)) {
            New-Item -Path $folderPath -ItemType Directory | Out-Null
            Write-Host "'$folder' folder created successfully in $rootPath"
        } else {
            Write-Host "'$folder' folder already exists in $rootPath"
        }
    }
}

# OPTION 3
function Copy-RomVideosToLocalFolder {
    $RomsDirectory = Read-Host "Enter the path to the ROMs directory"
    $VideoDirectory = Read-Host "Enter the path to the videos directory"
    $DestinationDirectory = Read-Host "Enter the path to the destination videos directory"

    if (-not (Test-Path -Path $DestinationDirectory)) {
        New-Item -Path $DestinationDirectory -ItemType Directory | Out-Null
    }

    $RomFilenames = Get-ChildItem -Path $RomsDirectory -File | ForEach-Object { $_.BaseName }
    $VideoFiles = Get-ChildItem -Path $VideoDirectory -File

    $totalFiles = $VideoFiles.Count
    $filesCopied = 0

    foreach ($VideoFile in $VideoFiles) {
        if ($RomFilenames -contains $VideoFile.BaseName) {
            $DestinationFilePath = Join-Path -Path $DestinationDirectory -ChildPath $VideoFile.Name
            if (-not (Test-Path -Path $DestinationFilePath)) {
                Copy-Item -Path $VideoFile.FullName -Destination $DestinationFilePath
                $filesCopied++
                Write-Host "Copied $filesCopied/$totalFiles '$($VideoFile.Name)'"
            } else {
                Write-Host "Skipped '$($VideoFile.Name)' (already exists)"
            }
        }
    }
    Write-Host "Finished copying $filesCopied files."
}

# OPTION 4
function Copy-RomVideosWithNamingAdjustments {
    $RomsDirectory = Read-Host "Enter the path to the ROMs directory"
    $VideoDirectory = Read-Host "Enter the path to the REMOTE video directory"
    $DestinationDirectory = Read-Host "Enter the path to the LOCAL videos directory"

    if (-not (Test-Path -Path $DestinationDirectory)) {
        New-Item -Path $DestinationDirectory -ItemType Directory | Out-Null
    }

    $RomItems = Get-ChildItem -Path $RomsDirectory
    $VideoFiles = Get-ChildItem -Path $VideoDirectory -File | Sort-Object Name  # Sorting files by name

    $totalFiles = $VideoFiles.Count
    $filesCopied = 0

    foreach ($VideoFile in $VideoFiles) {
        $normalizedVideoName = Normalize-Name -Name $VideoFile.BaseName
        foreach ($RomItem in $RomItems) {
            $normalizedRomName = Normalize-Name -Name $RomItem.BaseName
            if ($normalizedRomName -eq $normalizedVideoName) {
                $destinationFilePath = Join-Path -Path $DestinationDirectory -ChildPath ($RomItem.BaseName + $VideoFile.Extension)
                if (-not (Test-Path -Path $destinationFilePath)) {
                    Copy-Item -Path $VideoFile.FullName -Destination $destinationFilePath
                    $filesCopied++
                    Write-Host "Copied and renamed $filesCopied/$totalFiles '$($VideoFile.Name)' to match '$($RomItem.Name)'"
                } else {
                    Write-Host "Skipped '$($VideoFile.Name)' (already exists)"
                }
            }
        }
    }
}

# OPTION 5
function Compare-Files {
    $Directory1 = Read-Host "Enter the path of the first directory"
    $Directory2 = Read-Host "Enter the path of the second directory"

    $files1 = Get-ChildItem -Path $Directory1 -File | ForEach-Object { $_.BaseName }
    $files2 = Get-ChildItem -Path $Directory2 -File | ForEach-Object { $_.BaseName }

    $diff = Compare-Object -ReferenceObject $files1 -DifferenceObject $files2 -IncludeEqual -PassThru

    $missingIn2 = $diff | Where-Object { $_.SideIndicator -eq '<=' }
    $missingIn1 = $diff | Where-Object { $_.SideIndicator -eq '=>' }

    Write-Host "Files in ${Directory1} but not in ${Directory2}: $($missingIn2.Count)"
    $missingIn2 | ForEach-Object { Write-Host "  $_" }

    Write-Host "Files in ${Directory2} but not in ${Directory1}: $($missingIn1.Count)"
    $missingIn1 | ForEach-Object { Write-Host "  $_" }
}

# OPTION 6
function Compare-FoldersToFiles {
    $FoldersDirectory = Read-Host "Enter the path to the folders directory"
    $FilesDirectory = Read-Host "Enter the path to the files directory"

    $folderNames = Get-ChildItem -Path $FoldersDirectory -Directory | ForEach-Object { $_.Name }
    $fileBases = Get-ChildItem -Path $FilesDirectory -File | ForEach-Object { $_.BaseName }

    $diff = Compare-Object -ReferenceObject $folderNames -DifferenceObject $fileBases

    if ($diff) {
        Write-Host "Differences found:"
        $diff | ForEach-Object {
            if ($_.SideIndicator -eq '<=') {
                Write-Host "Folder missing as file: $($_.InputObject)"
            } else {
                Write-Host "File missing as folder: $($_.InputObject)"
            }
        }
    } else {
        Write-Host "No differences found. All folders have matching files."
    }
}

#OPTION 96
function Test-FoldersExist-LB {
    $defaultFolderPath = "R:\Launchbox\Games"

    $launchboxFolders = @("3DO Interactive Multiplayer", "AAE", "American Laser Games", "Amstrad CPC", "Amstrad GX4000", "Apple II", "Arcade", "Atari 2600", "Atari 5200", "Atari 7800", "Atari Jaguar", "Atari Jaguar CD", "Atari Lynx", "BBC Microcomputer System", "Capcom Play System", "Capcom Play System II", "Capcom Play System III", "Cave", "Clone Hero", "ColecoVision", "Commodore 64", "Commodore Amiga", "Commodore Amiga CD32", "Commodore CDTV", "Commodore VIC-20", "Creatronic Mega Duck", "Daphne", "Doujin Games", "Emerson Arcadia 2001", "Entex Adventure Vision", "Epoch Super Cassette Vision", "Examu Ex-Board", "Fairchild Channel F", "Fruit Machines", "GCE Vectrex", "GOG", "HB MAME", "Konami Handheld", "Magnavox Odyssey 2", "Mattel Intellivision", "Microsoft Xbox", "Microsoft Xbox 360", "MSU MD+", "MUGEN", "NEC PC Engine", "NEC PC-FX", "NEC TurboGrafx-16", "NEC TurboGrafx-CD", "Nintendo 3DS", "Nintendo 64", "Nintendo 64 HD", "Nintendo DS", "Nintendo Entertainment System", "Nintendo Entertainment System HD", "Nintendo Famicom Disk System", "Nintendo Game & Watch", "Nintendo Game Boy", "Nintendo Game Boy Advance", "Nintendo Game Boy Color", "Nintendo GameCube", "Nintendo Switch", "Nintendo Virtual Boy", "Nintendo Wii", "Nintendo Wii U", "Nokia N-Gage", "OpenBOR", "PC Engine SuperGrafx", "Philips CD-i", "Pinball Arcade", "Pinball FX2", "Pinball FX3", "Platform Categories", "Platforms", "Playlists", "PopCap", "Quiz Machines", "Recordings", "Sammy Atomiswave", "ScummVM", "Sega 32X", "Sega CD", "Sega CD 32X", "Sega Dreamcast", "Sega Game Gear", "Sega Genesis", "Sega Master System", "Sega Model 1", "Sega Model 2", "Sega Model 3", "Sega Naomi", "Sega Saturn", "Sega SG-1000", "Sega ST-V", "Sega System 16", "Sega System 24", "Sega System 32", "Sega Triforce", "Sega X Board", "Sega Y Board", "Sinclair ZX Spectrum", "Singe 2", "SNK Neo Geo AES", "SNK Neo Geo CD", "SNK Neo Geo Pocket", "SNK Neo Geo Pocket Color", "Sony Playstation", "Sony Playstation 2", "Sony Playstation 3", "Sony Playstation Vita", "Sony PSP", "Super Nintendo Entertainment System", "Super Nintendo MSU-1", "Taito NESiCAxLive", "Taito Type X", "Tekno Parrot", "Theme", "Tiger Game.com", "Tiger Handheld", "Trailer", "Videos", "Windows", "WonderSwan", "WonderSwan Color", "WoW Action Max", "ZiNc")

    $userInput = Read-Host "Do you want to use default folders to check? (Y/N)"
    
    if ($userInput -eq 'Y' -or $userInput -eq 'y') {
        $folderPath = $defaultFolderPath
        $foldersToCheck = $launchboxFolders
    } else {
        $folderPath = Read-Host "Enter the folder path to check"
        $foldersToCheck = $launchboxFolders
    }

    $missingFolders = @()
    foreach ($folder in $foldersToCheck) {
        $subFolderPath = Join-Path -Path $folderPath -ChildPath $folder
        if (-not (Test-Path -Path $subFolderPath -PathType Container)) {
            $missingFolders += $folder
        }
    }

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
}

# OPTION 97
function ZipEachFileIndividually {
    param (
        [string]$DirectoryPath = $(Read-Host "Please enter the directory path to zip files individually")
    )
    
    # Validate the provided directory path
    while (-not (Test-Path -Path $DirectoryPath -PathType Container)) {
        Write-Host "The specified directory does not exist or is not valid."
        $DirectoryPath = Read-Host "Please enter a valid directory path to zip files individually"
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    Add-Type -AssemblyName System.IO.Compression

    # Define an array of compressed file extensions to skip
    $compressedFileExtensions = @('.zip', '.rar', '.7z', '.tar', '.gz', '.txt')

    $files = Get-ChildItem -Path $DirectoryPath -File | Where-Object { $compressedFileExtensions -notcontains $_.Extension.ToLower() }
    foreach ($file in $files) {
        $zipFilePath = Join-Path -Path $DirectoryPath -ChildPath ($file.BaseName + ".zip")
        
        if (-Not (Test-Path -Path $zipFilePath)) {
            try {
                $zip = [System.IO.Compression.ZipFile]::Open($zipFilePath, [System.IO.Compression.ZipArchiveMode]::Create)
                $zipEntry = $zip.CreateEntry($file.Name, [System.IO.Compression.CompressionLevel]::Optimal)
                $fileStream = [System.IO.File]::OpenRead($file.FullName)
                $entryStream = $zipEntry.Open()
                
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
}

# OPTION 98
function Find-DuplicateFileName {
    $Directory = Read-Host "Enter the path of the directory"

    $files = Get-ChildItem -Path $Directory -File
    $nameGroups = $files | Group-Object -Property { Normalize-Name -Name $_.BaseName }

    $duplicates = $nameGroups | Where-Object { $_.Count -gt 1 }

    if ($duplicates) {
        Write-Host "Duplicate file names found:"
        foreach ($group in $duplicates) {
            Write-Host "Name: $($group.Name)"
            $group.Group | ForEach-Object { Write-Host " - $($_.Name)" }
        }
    } else {
        Write-Host "No duplicate file names found."
    }
}


# OPTION 99
function Find-DuplicateFileSize {
    $Directory = Read-Host "Enter the path of the directory"

    $files = Get-ChildItem -Path $Directory -File
    $sizeGroups = $files | Group-Object -Property Length

    $duplicates = $sizeGroups | Where-Object { $_.Count -gt 1 }

    if ($duplicates) {
        Write-Host "Duplicate file sizes found:"
        foreach ($group in $duplicates) {
            Write-Host "Size: $($group.Name) bytes"
            $group.Group | ForEach-Object { Write-Host " - $($_.Name)" }
        }
    } else {
        Write-Host "No duplicate file sizes found."
    }
}

# Normalize Name Characters
function Normalize-Name {
    param (
        [string]$Name
    )

    $Name -replace '\[.*?\]|\(.*?\)|_|-01|-02|.ps3', '' -replace '\s+', ' ' | ForEach-Object { $_.Trim() }
}

# MENU
do {
    Show-Menu
    $selection = Read-Host "Please make a selection"
    switch ($selection) {
        '1' { Test-FoldersExist }
        '2' { Initialize-BiosImagesVideosFolders }
        '3' { Copy-RomVideosToLocalFolder }
        '4' { Copy-RomVideosWithNamingAdjustments }
        '5' { Compare-Files }
        '6' { Compare-FoldersToFiles }
        '96' { Test-FoldersExist-LB }
        '97' { ZipEachFileIndividually }
        '98' { Find-DuplicateFileName }
        '99' { Find-DuplicateFileSize }
        'q' { break }
        default { Write-Host "Invalid selection. Please try again." }
    }
    pause
} while ($selection -ne 'q')
