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
}

# OPTION 4
function Copy-RomVideosWithNamingAdjustments {
    $RomsDirectory = Read-Host "Enter the path to the ROMs directory"
    $VideoDirectory = Read-Host "Enter the path to the videos directory"
    $DestinationDirectory = Read-Host "Enter the path to the destination videos directory"

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

    $Name -replace '\[.*?\]|\(.*?\)', '' -replace '\s+', ' ' | ForEach-Object { $_.Trim() }
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
        '98' { Find-DuplicateFileName }
        '99' { Find-DuplicateFileSize }
        'q' { break }
        default { Write-Host "Invalid selection. Please try again." }
    }
    pause
} while ($selection -ne 'q')
