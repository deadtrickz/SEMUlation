Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ShowConsole = $True

if (-not $ShowConsole) {
    Add-Type -Name Win -Namespace HideConsole -MemberDefinition @"
        [DllImport("kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();
        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
"@ -Language CSharp

    $consolePtr = [HideConsole.Win]::GetConsoleWindow()
    [HideConsole.Win]::ShowWindow($consolePtr, 0)  # 0 = SW_HIDE
}

# Functions
function Check-MissingVideos {
    param (
        [string]$RomsDirectory,
        [bool]$OutputToFile,
        [System.Windows.Forms.ProgressBar]$progressBar
    )

    $progressBar.Value = 10
    $subDirectories = @("3do", "ags", "amiga", "amiga1200", "amiga600", "amigacd32", "amstradcpc", "android", "apple2", "apple2gs", "arcade", "arcadia", "arduboy", "astrocde", "atari2600", "atari5200", "atari7800", "atari800", "atarijaguar", "atarijaguarcd", "atarilynx", "atarist", "atarixe", "atomiswave", "bbcmicro", "c16", "c64", "cavestory", "cdimono1", "cdtv", "chailove", "channelf", "cloud", "coco", "colecovision", "cps", "cps1", "cps2", "cps3", "crvision", "daphne", "desktop", "doom", "dos", "dragon32", "dreamcast", "easyrpg", "epic", "famicom", "fba", "fbneo", "fds", "flash", "fmtowns", "gameandwatch", "gamecom", "gamegear", "gb", "gba", "gbc", "gamecube", "gx4000", "intellivision", "j2me", "kodi", "lcdgames", "lutris", "lutro", "macintosh", "mame", "mame-advmame", "mame-mame4all", "mastersystem", "megacd", "megacdjp", "megadrive", "megadrivejp", "megaduck", "mess", "model2", "model3", "moonlight", "moto", "msx", "msx1", "msx2", "msxturbor", "mugen", "multivision", "n3ds", "n64", "n64dd", "naomi", "naomigd", "nds", "neogeo", "neogeocd", "neogeocdjp", "nes", "ngp", "ngpc", "odyssey2", "openbor", "oric", "palm", "pc", "pc88", "pc98", "pcengine", "pcenginecd", "pcfx", "pico8", "pokemini", "ports", "primehacks", "ps2", "ps3", "ps4", "psp", "psvita", "psx", "pv1000", "quake", "remoteplay", "samcoupe", "satellaview", "saturn", "saturnjp", "scummvm", "sega32x", "sega32xjp", "sega32xna", "segacd", "sfc", "sg-1000", "sgb", "snes", "sneshd", "snesna", "solarus", "spectravideo", "steam", "stratagus", "sufami", "supergrafx", "supervision", "switch", "symbian", "tanodragon", "tg-cd", "tg16", "ti99", "tic80", "to8", "trs-80", "uzebox", "vectrex", "vic20", "videopac", "virtualboy", "vsmile", "wasm4", "wii", "wiiu", "windows", "wonderswan", "wonderswancolor", "x1", "x68000", "xbox", "xbox360", "xbla", "zmachine", "zx81", "zxspectrum")

    foreach ($subDir in $subDirectories) {
        $romSubDir = Join-Path $RomsDirectory $subDir
        $mediaSubDir = Join-Path $romSubDir "videos"

        if (Test-Path $romSubDir) {
            # Get rom files excluding .txt and .nfo
            $romFiles = Get-ChildItem $romSubDir -File | Where-Object { $_.Extension -notin @('.txt', '.nfo') }

            if ($romFiles.Count -eq 0) {
                # No ROM files, skip this directory (don't create videos folder)
                continue
            }

            if (-not (Test-Path $mediaSubDir)) {
                # Videos folder does NOT exist but ROMs exist — create videos folder
                New-Item -ItemType Directory -Path $mediaSubDir | Out-Null
            }

            # Now check for missing videos as before
            $outputPath = Join-Path $mediaSubDir "_missing-videos.txt"
            if (Test-Path $outputPath) { Remove-Item $outputPath }

            $videoFiles = Get-ChildItem $mediaSubDir -File | Where-Object { $_.Name -ne "_missing-videos.txt" }

            $romNames = $romFiles.BaseName | Select-Object -Unique
            $videoNames = $videoFiles.BaseName | ForEach-Object { $_ -replace '-video$', '' } | Select-Object -Unique

            $missingVideos = Compare-Object $romNames $videoNames | Where-Object { $_.SideIndicator -eq "<=" } | Select-Object -ExpandProperty InputObject

            if ($missingVideos.Count -gt 0) {
                Write-Log "$subDir is missing $($missingVideos.Count) videos."

                # Always write missing filenames to the file
                $missingVideos | Out-File $outputPath -Append

                # Optionally also show filenames in the GUI log box
#                if ($OutputToFile) {
#                    foreach ($video in $missingVideos) {
#                        Write-Log "  $video"
#                    }
#                }
            }
        }
    }

    Write-Log "Check complete."
    $progressBar.Value = 100
    Start-Sleep -Milliseconds 500
    $progressBar.Value = 0
}



function Sync-MediaFromRemote {
    param (
        [string]$localRoot,
        [string]$remoteRoot,
        [System.Windows.Forms.ProgressBar]$progressBar
    )

    $progressBar.Value = 10
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
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
        Write-Log "Processing [$system]..."

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

    foreach ($system in $subDirectories) {
        if (Test-Path (Join-Path $localRoot $system)) {
            Update-System $system
        }
    }

    if ($missingMedia.Values | Where-Object { $_.Count -gt 0 }) {
        Write-Log "`n=== Missing Media Report ==="
        foreach ($system in $missingMedia.Keys) {
            Write-Log "[$system]"
            foreach ($rom in $missingMedia[$system].Keys) {
                $types = ($missingMedia[$system][$rom] | Sort-Object) -join ", "
                Write-Host "$rom ($types)"
            }
            Write-Host ""
        }
    } else {
        Write-Log "`nAll media present!"
    }

    $progressBar.Value = 100
    Start-Sleep -Milliseconds 500
    $progressBar.Value = 0
}


# Logging Function
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $logBox.AppendText("[$timestamp] $message`r`n")
}

# Tab Creation
function Create-EmuTab {
    param (
        [string]$tabName,
        [array]$operations,
        [hashtable]$radioMap
    )

    $tab = New-Object System.Windows.Forms.TabPage
    $tab.Text = $tabName

    $yOffset = 20

    # Create radio buttons and map them to actions
    foreach ($op in $operations) {
        $radio = New-Object System.Windows.Forms.RadioButton
        $radio.Text = $op.Label
        $radio.Location = New-Object System.Drawing.Point(20, $yOffset)
        $radio.AutoSize = $true
        $tab.Controls.Add($radio)
        $radioMap[$radio] = $op.Action
        $yOffset += 25
    }

    # Local Dir input
    $labelLocal = New-Object System.Windows.Forms.Label
    $labelLocal.Text = "Local Dir:"
    $labelLocal.Location = New-Object System.Drawing.Point(20, $yOffset)
    $labelLocal.AutoSize = $true
    $tab.Controls.Add($labelLocal)

    $textLocal = New-Object System.Windows.Forms.TextBox
    $textLocal.Size = New-Object System.Drawing.Size(300,20)
    $textLocal.Location = New-Object System.Drawing.Point(130, $yOffset)
    $tab.Controls.Add($textLocal)

    $browseBtn = New-Object System.Windows.Forms.Button
    $browseBtn.Text = "Browse"
    $browseBtn.Location = New-Object System.Drawing.Point(440, $yOffset)
    $browseBtn.Add_Click({
        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($folderBrowser.ShowDialog() -eq "OK") {
            $textLocal.Text = $folderBrowser.SelectedPath
        }
    })
    $tab.Controls.Add($browseBtn)

    $yOffset += 30

    # Remote Dir input
    $labelRemote = New-Object System.Windows.Forms.Label
    $labelRemote.Text = "Remote Dir:"
    $labelRemote.Location = New-Object System.Drawing.Point(20, $yOffset)
    $labelRemote.AutoSize = $true
    $tab.Controls.Add($labelRemote)

    $textRemote = New-Object System.Windows.Forms.TextBox
    $textRemote.Size = New-Object System.Drawing.Size(300,20)
    $textRemote.Location = New-Object System.Drawing.Point(130, $yOffset)
    $tab.Controls.Add($textRemote)

    # Return tab and inputs for external use
    return [PSCustomObject]@{
        Tab         = $tab
        TextLocal   = $textLocal
        TextRemote  = $textRemote
    }
}

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "sEMUlation"
$form.Size = New-Object System.Drawing.Size(550,450)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false

$radioMap = @{}
$yOffset = 20

# Create TabControl
$tabs = New-Object System.Windows.Forms.TabControl
$tabs.Size = New-Object System.Drawing.Size(480, 260)
$tabs.Dock = 'Fill'
$tabs.Location = New-Object System.Drawing.Point(10,10)
$tabs.Add_SelectedIndexChanged({
    foreach ($radio in $radioMap.Keys) {
        $radio.Checked = $false
    }
})


$retrobatOperations = @(
    @{ Label = "Check Missing Videos"; Action = { Check-MissingVideos -RomsDirectory $textLocal.Text -OutputToFile $true -progressBar $progressBar } },
    @{ Label = "Sync Media from Remote"; Action = { Sync-MediaFromRemote -localRoot $textLocal.Text -remoteRoot $textRemote.Text -progressBar $progressBar } },
    @{ Label = "Convert Media Format"; Action = { Convert-MediaFormat -sourceDir $textLocal.Text -progressBar $progressBar } }
)

$launchboxOperations = @(
    @{ Label = "Check Missing Videos"; Action = { Check-MissingVideos -RomsDirectory $launchTextLocal.Text -OutputToFile $true -progressBar $progressBar } },
    @{ Label = "Sync Media from Remote"; Action = { Sync-MediaFromRemote -localRoot $launchTextLocal.Text -remoteRoot $launchTextRemote.Text -progressBar $progressBar } },
    @{ Label = "Convert Media Format"; Action = { Convert-MediaFormat -sourceDir $launchTextLocal.Text -progressBar $progressBar } }
)

$retroTabBundle = Create-EmuTab -tabName "RetroBat" -operations $retrobatOperations -radioMap $radioMap
$tabs.TabPages.Add($retroTabBundle.Tab)
$launchTabBundle = Create-EmuTab -tabName "LaunchBox" -operations $launchboxOperations -radioMap $radioMap
$tabs.TabPages.Add($launchTabBundle.Tab)

# Log Output
$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Multiline = $true
$logBox.ScrollBars = 'Vertical'
$logBox.ReadOnly = $true
$logBox.WordWrap = $true
$logBox.Anchor = 'Top,Left,Right,Bottom'


# Run Button
$runBtn = New-Object System.Windows.Forms.Button
$runBtn.Text = "Run"
$runBtn.Anchor = 'Bottom,Left'
$runBtn.Add_Click({
    $selected = $radioMap.Keys | Where-Object { $_.Checked }
    if ($selected.Count -eq 1) {
        & $radioMap[$selected[0]]
    } else {
        [System.Windows.Forms.MessageBox]::Show("Please select an operation.")
    }
})

# Add TabControl to form
$form.Controls.Add($tabs)

# Progress Bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Size = New-Object System.Drawing.Size(460,20)
$progressBar.Style = 'Continuous'
$progressBar.Left = [int](($bottomPanel.ClientSize.Width - $progressBar.Width) / 2)


# Bottom Panel
$bottomPanel = New-Object System.Windows.Forms.Panel
$bottomPanel.Dock = 'Bottom'
$bottomPanel.Height = 180
$form.Controls.Add($bottomPanel)
$bottomPanel.Controls.Add($runBtn)

$bottomPanel.Controls.Add($progressBar)
$bottomPanel.Controls.Add($logBox)
$runBtn.Location      = New-Object System.Drawing.Point(10, 10)
$progressBar.Location = New-Object System.Drawing.Point(10, 45)
$logBox.Location      = New-Object System.Drawing.Point(10, 75)
$logBox.Size        = New-Object System.Drawing.Size(460, 90)
$logBox.Width += 60

# Optional: capture inputs for use in your operations
$textLocal = $retroTabBundle.TextLocal
$textRemote = $retroTabBundle.TextRemote
$launchTextLocal  = $launchTabBundle.TextLocal
$launchTextRemote = $launchTabBundle.TextRemote

# Show the form
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
