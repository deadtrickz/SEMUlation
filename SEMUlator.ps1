function Show-Menu {
    Clear-Host
    Write-Host @"
    
><><><><><><><><><><
SEMUlator Rom Tools
~ ~~~~ V0.7a ~~~~~ ~
by Deadtrickz
><><><><><><><><><><

"@ -ForegroundColor Yellow
    Write-Host "1: Verify And Create Rom Folders In R:\roms"
    Write-Host "2: Copy EmulationStation's 'roms' folder to R:\"
    Write-Host "3: Check/Create 'bios', 'images', and 'videos' folders in R:\"
    Write-Host "4: Run A Diff On 2 folders"
    Write-Host "5: Copy Rom Videos From Remote Folder To Local Folder"
    Write-Host "6: Find Duplicate File Sizes In A Folder"
    Write-Host "Q: Quit"
}

function Test-FoldersExist {
    param (
        [string]$folderPath,
        [string[]]$foldersToCheck
    )

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
        $copy = Read-Host "Do you want to copy missing folders from _dev/roms? (Yes/No)"
        if ($copy -eq "Yes" -or $copy -eq "yes" -or $copy -eq "Y" -or $copy -eq "y") {
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
        Write-Host "All required folders exist in ${folderPath}."
    }
}

function Initialize-BiosImagesVideosFolders {
    $foldersToCheck = @("bios", "images", "videos")
    $rootPath = "R:\"

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

function Copy-RomsFolder {
    $sourcePath = Join-Path -Path $PSScriptRoot -ChildPath "_dev\roms"
    $destinationPath = "R:\roms"

    if (Test-Path -Path $destinationPath -PathType Container) {
        Write-Host "The 'roms' folder already exists in R:\"
        $overwrite = Read-Host "Do you want to overwrite it? (Y/N)"
        if ($overwrite -eq "Y" -or $overwrite -eq "y") {
            Write-Host "Overwriting 'roms' folder..."
            Remove-Item -Path $destinationPath -Recurse -Force
            Copy-Item -Path $sourcePath -Destination $destinationPath -Recurse -Force
            Write-Host "'roms' folder copied successfully to R:\"
        } else {
            Write-Host "Operation aborted."
        }
    } else {
        Write-Host "Copying 'roms' folder to R:\..."
        Copy-Item -Path $sourcePath -Destination $destinationPath -Recurse -Force
        Write-Host "'roms' folder copied successfully to R:\"
    }
}

function Compare-Files {
    param (
        [string]$Directory1,
        [string]$Directory2
    )

    $files1 = Get-ChildItem -Path $Directory1 -File | ForEach-Object { $_.BaseName }
    $files2 = Get-ChildItem -Path $Directory2 -File | ForEach-Object { $_.BaseName }

    $diff = Compare-Object -ReferenceObject $files1 -DifferenceObject $files2 -IncludeEqual -PassThru

    $missingIn2 = $diff | Where-Object { $_.SideIndicator -eq '<=' }
    $missingIn1 = $diff | Where-Object { $_.SideIndicator -eq '=>' }

    Write-Host "Files in $($Directory1) but not in $($Directory2): $($missingIn2.Count)"
    $missingIn2 | ForEach-Object { Write-Host "  $_" }

    Write-Host "Files in $($Directory2) but not in $($Directory1): $($missingIn1.Count)"
    $missingIn1 | ForEach-Object { Write-Host "  $_" }
}

function Find-DuplicateFileSize {
    param (
        [string]$Directory
    )

    $files = Get-ChildItem -Path $Directory -File
    $fileSizes = @{}

    foreach ($file in $files) {
        $fileSize = $file.Length
        if ($fileSizes.ContainsKey($fileSize)) {
            $fileSizes[$fileSize] += @($file.Name)
        } else {
            $fileSizes.Add($fileSize, @($file.Name))
        }
    }

    $duplicateFileSizes = $fileSizes.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }

    if ($duplicateFileSizes.Count -eq 0) {
        Write-Host "No duplicate file sizes found in $($Directory)."
    } else {
        Write-Host "Duplicate file sizes found in $($Directory):"
        foreach ($item in $duplicateFileSizes) {
            Write-Host "File Size: $($item.Key) Bytes"
            Write-Host "Files: $($item.Value -join ', ')"
        }
    }
}

function Copy-RomVideosToLocalFolder {
    param (
        [string]$RomsDirectory,
        [string]$VideoDirectory,
        [string]$DestinationDirectory
    )

    if (-not (Test-Path -Path $DestinationDirectory)) {
        New-Item -Path $DestinationDirectory -ItemType Directory | Out-Null
    }

    $RomFilenames = Get-ChildItem -Path $RomsDirectory -File | ForEach-Object { $_.BaseName }
    $VideoFiles = Get-ChildItem -Path $VideoDirectory -File
    $FilesToCopy = @()

    foreach ($VideoFile in $VideoFiles) {
        if ($RomFilenames -contains $VideoFile.BaseName) {
            $DestinationFilePath = Join-Path -Path $DestinationDirectory -ChildPath $VideoFile.Name
            if (-not (Test-Path -Path $DestinationFilePath)) {
                $FilesToCopy += $VideoFile
            }
        }
    }

    $TotalFiles = $FilesToCopy.Count
    $CopiedFiles = 0

    foreach ($File in $FilesToCopy) {
        $DestinationFilePath = Join-Path -Path $DestinationDirectory -ChildPath $File.Name
        Copy-Item -Path $File.FullName -Destination $DestinationFilePath
        $CopiedFiles++
        Write-Progress -Activity "Copying Videos" -Status "$CopiedFiles/$TotalFiles Files Copied" -PercentComplete (($CopiedFiles / $TotalFiles) * 100) -CurrentOperation "Copying: $($File.Name)"
    }

    Write-Progress -Activity "Copying Videos" -Status "Completed" -Completed

    if ($CopiedFiles -eq $TotalFiles) {
        Write-Host "All files copied successfully."
    } else {
        Write-Host "Some files were not copied."
    }
}

do {
    Show-Menu
    $selection = Read-Host "Please make a selection"
    switch ($selection) {
        '1' {
            $foldersToCheck = @("3do", "ags", "amiga", "amiga1200", "amiga600", "amigacd32", "amstradcpc", "android", "apple2", "apple2gs", "arcade", "arcadia", "arduboy", "astrocde", "atari2600", "atari5200", "atari7800", "atari800", "atarijaguar", "atarijaguarcd", "atarilynx", "atarist", "atarixe", "atomiswave", "bbcmicro", "c16", "c64", "cavestory", "cdimono1", "cdtv", "chailove", "channelf", "cloud", "coco", "colecovision", "cps", "cps1", "cps2", "cps3", "crvision", "daphne", "desktop", "doom", "dos", "dragon32", "dreamcast", "easyrpg", "epic", "famicom", "fba", "fbneo", "fds", "flash", "fmtowns", "gameandwatch", "gamecom", "gamegear", "gb", "gba", "gbc", "gc", "genesis", "genesiswide", "gx4000", "intellivision", "j2me", "kodi", "lcdgames", "lutris", "lutro", "macintosh", "mame-advmame", "mame-mame4all", "mame", "mastersystem", "megacd", "megacdjp", "megadrive", "megadrivejp", "megaduck", "mess", "model2", "model3", "moonlight", "moto", "msx", "msx1", "msx2", "msxturbor", "mugen", "multivision", "n3ds", "n64", "n64dd", "naomi", "naomi2", "naomigd", "nds", "neogeo", "neogeocd", "neogeocdjp", "nes", "ngp", "ngpc", "odyssey2", "openbor", "oric", "palm", "pc", "pc88", "pc98", "pcengine", "pcenginecd", "pcfx", "pico8", "pokemini", "ports", "primehacks", "ps2", "ps3", "ps4", "psp", "psvita", "psx", "pv1000", "quake", "remoteplay", "samcoupe", "satellaview", "saturn", "saturnjp", "scummvm", "sega32x", "sega32xjp", "sega32xna", "segacd", "sfc", "sg-1000", "sgb", "snes", "sneshd", "snesna", "solarus", "spectravideo", "steam", "stratagus", "sufami", "supergrafx", "supervision", "switch", "symbian", "tanodragon", "tg-cd", "tg16", "ti99", "tic80", "to8", "trs-80", "uzebox", "vectrex", "vic20", "videopac", "virtualboy", "vsmile", "wasm4", "wii", "wiiu/roms", "wonderswan", "wonderswancolor", "x1", "x68000", "xbox", "xbox360", "zmachine", "zx81", "zxspectrum")
            Test-FoldersExist -folderPath "R:\roms" -foldersToCheck $foldersToCheck
        }
        '2' { Copy-RomsFolder }
        '3' { Initialize-BiosImagesVideosFolders }
        '4' {
            $Directory1 = Read-Host "Enter the path of the first directory"
            $Directory2 = Read-Host "Enter the path of the second directory"
            Compare-Files -Directory1 $Directory1 -Directory2 $Directory2
        }
        '5' {
            $RomsDirectory = Read-Host "Enter the path to the ROMs directory"
            $VideoDirectory = Read-Host "Enter the path to the videos directory"
            $DestinationDirectory = Read-Host "Enter the path to the destination videos directory"
            Copy-RomVideosToLocalFolder -RomsDirectory $RomsDirectory -VideoDirectory $VideoDirectory -DestinationDirectory $DestinationDirectory
        }
        '6' {
            $Directory = Read-Host "Enter the path of the directory to find duplicate file sizes"
            Find-DuplicateFileSize -Directory $Directory
        }
        'q' { break }
        default { Write-Host "Invalid selection. Please try again." }
    }
    pause
} while ($selection -ne 'q')