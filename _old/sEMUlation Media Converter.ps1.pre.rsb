param(
    [string]$frontendUsing,
    [string]$frontendFrom,
    [string]$localRomPath,
    [string]$remoteMediaPath,
    [string]$localMediaPath
)

# ---------- GUI ----------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[void][System.Windows.Forms.Application]::EnableVisualStyles()
[void][System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

function Write-Log { param($m) Write-Host $m }

$form = New-Object Windows.Forms.Form
$form.Text = "Media Converter"
$form.Size = New-Object Drawing.Size(760, 420)
$form.StartPosition = "CenterScreen"

$lblFrontendUsing = New-Object Windows.Forms.Label
$lblFrontendUsing.Text = "Frontend I'm Using:"
$lblFrontendUsing.Location = New-Object Drawing.Point(10, 20)
$lblFrontendUsing.AutoSize = $true
$form.Controls.Add($lblFrontendUsing)

$cboFrontendUsing = New-Object Windows.Forms.ComboBox
$cboFrontendUsing.Location = New-Object Drawing.Point(150, 18)
$cboFrontendUsing.Size = New-Object Drawing.Size(220, 22)
$cboFrontendUsing.DropDownStyle = 'DropDownList'
$cboFrontendUsing.Items.AddRange(@("Batocera", "EmuDeck", "LaunchBox", "RetroBat", "RetroDeck"))
$cboFrontendUsing.SelectedIndex = 3  # RetroBat default
$form.Controls.Add($cboFrontendUsing)

$lblFrontendFrom = New-Object Windows.Forms.Label
$lblFrontendFrom.Text = "Media is From:"
$lblFrontendFrom.Location = New-Object Drawing.Point(10, 55)
$lblFrontendFrom.AutoSize = $true
$form.Controls.Add($lblFrontendFrom)

$cboFrontendFrom = New-Object Windows.Forms.ComboBox
$cboFrontendFrom.Location = New-Object Drawing.Point(150, 53)
$cboFrontendFrom.Size = New-Object Drawing.Size(220, 22)
$cboFrontendFrom.DropDownStyle = 'DropDownList'
$cboFrontendFrom.Items.AddRange(@("Batocera", "EmuDeck", "LaunchBox", "RetroBat", "RetroDeck"))
$cboFrontendFrom.SelectedIndex = 3  # RetroBat default
$form.Controls.Add($cboFrontendFrom)

$lblRom = New-Object Windows.Forms.Label
$lblRom.Text = "Local ROM Path:"
$lblRom.Location = New-Object Drawing.Point(10, 90)
$lblRom.AutoSize = $true
$form.Controls.Add($lblRom)

$txtLocalRomPath = New-Object Windows.Forms.TextBox
$txtLocalRomPath.Location = New-Object Drawing.Point(150, 88)
$txtLocalRomPath.Size = New-Object Drawing.Size(580, 22)
$form.Controls.Add($txtLocalRomPath)

$lblRemote = New-Object Windows.Forms.Label
$lblRemote.Text = "Remote Media Path:"
$lblRemote.Location = New-Object Drawing.Point(10, 125)
$lblRemote.AutoSize = $true
$form.Controls.Add($lblRemote)

$txtRemoteMediaPath = New-Object Windows.Forms.TextBox
$txtRemoteMediaPath.Location = New-Object Drawing.Point(150, 123)
$txtRemoteMediaPath.Size = New-Object Drawing.Size(580, 22)
$form.Controls.Add($txtRemoteMediaPath)

$lblLocal = New-Object Windows.Forms.Label
$lblLocal.Text = "Optional Local Media Path (override):"
$lblLocal.Location = New-Object Drawing.Point(10, 160)
$lblLocal.AutoSize = $true
$form.Controls.Add($lblLocal)

$txtLocalMediaPath = New-Object Windows.Forms.TextBox
$txtLocalMediaPath.Location = New-Object Drawing.Point(250, 158)
$txtLocalMediaPath.Size = New-Object Drawing.Size(480, 22)
$form.Controls.Add($txtLocalMediaPath)

$lblSync = New-Object Windows.Forms.Label
$lblSync.Text = "Sync:"
$lblSync.Location = New-Object Drawing.Point(10, 195)
$lblSync.AutoSize = $true
$form.Controls.Add($lblSync)

$rbImages = New-Object Windows.Forms.RadioButton
$rbImages.Text = "Images"
$rbImages.Location = New-Object Drawing.Point(150, 193)
$rbImages.AutoSize = $true
$form.Controls.Add($rbImages)

$rbVideos = New-Object Windows.Forms.RadioButton
$rbVideos.Text = "Videos"
$rbVideos.Location = New-Object Drawing.Point(220, 193)
$rbVideos.AutoSize = $true
$form.Controls.Add($rbVideos)

$rbBoth = New-Object Windows.Forms.RadioButton
$rbBoth.Text = "Images and Videos"
$rbBoth.Location = New-Object Drawing.Point(290, 193)
$rbBoth.AutoSize = $true
$rbBoth.Checked = $true
$form.Controls.Add($rbBoth)

$progress = New-Object Windows.Forms.ProgressBar
$progress.Location = New-Object Drawing.Point(150, 230)
$progress.Size = New-Object Drawing.Size(580, 18)
$progress.Style = 'Continuous'
$progress.Minimum = 0
$progress.Maximum = 100
$progress.Value = 0
$form.Controls.Add($progress)

$btn = New-Object Windows.Forms.Button
$btn.Text = "Process Media"
$btn.Location = New-Object Drawing.Point(150, 265)
$btn.Size = New-Object Drawing.Size(130, 30)
$form.Controls.Add($btn)

# --- Hint / help label ---
$lblHint = New-Object Windows.Forms.Label
$lblHint.Location = New-Object Drawing.Point(10, 310)
$lblHint.Size = New-Object Drawing.Size(720, 60)
$lblHint.AutoSize = $false
$lblHint.Text = ""
$form.Controls.Add($lblHint)

function Update-HintText {
    param([string]$usingFE, [string]$fromFE)

    $lines = @()

    switch ($fromFE) {
        'LaunchBox' {
            $lines += "LaunchBox (source): look for ...\LaunchBox\Images\<Platform>\{Screenshots|Marquees|Covers} and \Videos\<Platform>"
        }
        'EmuDeck' {
            $lines += "EmuDeck (source): <root>\downloaded_media\<system>\{screenshots|marquees|covers|videos}"
        }
        'RetroDeck' {
            $lines += "RetroDeck (source): <root>\downloaded_media\<system>\{screenshots|marquees|covers|videos}"
        }
        default {
            $lines += "Flat (source): <root>\<system>\images and \videos with -image/-marquee/-thumb/-video"
        }
    }

    switch ($usingFE) {
        'EmuDeck' {
            $lines += "EmuDeck (dest): requires “Optional Local Media Path”. Media written to <that>\downloaded_media\<system>\{screenshots|marquees|covers|videos}."
            $lines += "Typical Linux locations (FYI when copying later):"
            $lines += "  ~/.emulationstation/downloaded_media/   or   /run/media/mmcblk0p1/Emulation/tools/downloaded_media/"
        }
        'RetroDeck' {
            $lines += "RetroDeck (dest): requires “Optional Local Media Path”. Media written to <that>\downloaded_media\<system>\{screenshots|marquees|covers|videos}."
            $lines += "Typical Linux location (FYI):"
            $lines += "  ~/.var/app/net.retrodeck.retrodeck/config/emulationstation/downloaded_media/"
        }
        default {
            $lines += "Destination uses your frontend’s normal layout."
        }
    }

    $lblHint.Text = ($lines -join [Environment]::NewLine)
}

# Wire up dynamic updates
$cboFrontendUsing.add_SelectedIndexChanged({
    Update-HintText -usingFE $cboFrontendUsing.SelectedItem -fromFE $cboFrontendFrom.SelectedItem
})
$cboFrontendFrom.add_SelectedIndexChanged({
    Update-HintText -usingFE $cboFrontendUsing.SelectedItem -fromFE $cboFrontendFrom.SelectedItem
})
# Initial text
Update-HintText -usingFE $cboFrontendUsing.SelectedItem -fromFE $cboFrontendFrom.SelectedItem


# ---------- Canonical systems/media ----------
$SystemCanonical = @{
  # --- Consoles you already had (kept) ---
  "genesis"       = @{ RetroBat="megadrive";      Batocera="megadrive";      EmuDeck="genesis";        RetroDeck="genesis";        LaunchBox="Sega Genesis" }
  "mame"          = @{ RetroBat="mame";           Batocera="mame";           EmuDeck="mame";           RetroDeck="mame";           LaunchBox="Arcade" }
  "n64"           = @{ RetroBat="n64";            Batocera="n64";            EmuDeck="n64";            RetroDeck="n64";            LaunchBox="Nintendo 64" }
  "nes"           = @{ RetroBat="nes";            Batocera="nes";            EmuDeck="nes";            RetroDeck="nes";            LaunchBox="Nintendo Entertainment System" }
  "ps2"           = @{ RetroBat="ps2";            Batocera="ps2";            EmuDeck="ps2";            RetroDeck="ps2";            LaunchBox="Sony PlayStation 2" }
  "psp"           = @{ RetroBat="psp";            Batocera="psp";            EmuDeck="psp";            RetroDeck="psp";            LaunchBox="Sony PSP" }
  "psx"           = @{ RetroBat="psx";            Batocera="psx";            EmuDeck="psx";            RetroDeck="psx";            LaunchBox="Sony PlayStation" }
  "gba"           = @{ RetroBat="gba";            Batocera="gba";            EmuDeck="gba";            RetroDeck="gba";            LaunchBox="Nintendo Game Boy Advance" }
  "gb"            = @{ RetroBat="gb";             Batocera="gb";             EmuDeck="gb";             RetroDeck="gb";             LaunchBox="Nintendo Game Boy" }
  "gbc"           = @{ RetroBat="gbc";            Batocera="gbc";            EmuDeck="gbc";            RetroDeck="gbc";            LaunchBox="Nintendo Game Boy Color" }
  "mastersystem"  = @{ RetroBat="mastersystem";   Batocera="mastersystem";   EmuDeck="mastersystem";   RetroDeck="mastersystem";   LaunchBox="Sega Master System" }
  "snes"          = @{ RetroBat="snes";           Batocera="snes";           EmuDeck="snes";           RetroDeck="snes";           LaunchBox="Super Nintendo Entertainment System" }
  "3do"           = @{ RetroBat="3do";            Batocera="3do";            EmuDeck="3do";            RetroDeck="3do";            LaunchBox="3DO Interactive Multiplayer" }
  "ags"           = @{ RetroBat="ags";            Batocera="ags";            EmuDeck="ags";            RetroDeck="ags";            LaunchBox="Adventure Game Studio" }
  "amiga"         = @{ RetroBat="amiga";          Batocera="amiga";          EmuDeck="amiga";          RetroDeck="amiga";          LaunchBox="Commodore Amiga" }
  "amiga1200"     = @{ RetroBat="amiga1200";      Batocera="amiga1200";      EmuDeck="amiga1200";      RetroDeck="amiga1200";      LaunchBox="Commodore Amiga 1200" }
  "amiga600"      = @{ RetroBat="amiga600";       Batocera="amiga600";       EmuDeck="amiga600";       RetroDeck="amiga600";       LaunchBox="Commodore Amiga 600" }
  "amigacd32"     = @{ RetroBat="amigacd32";      Batocera="amigacd32";      EmuDeck="amigacd32";      RetroDeck="amigacd32";      LaunchBox="Commodore Amiga CD32" }
  "amstradcpc"    = @{ RetroBat="amstradcpc";     Batocera="amstradcpc";     EmuDeck="amstradcpc";     RetroDeck="amstradcpc";     LaunchBox="Amstrad CPC" }
  "android"       = @{ RetroBat="android";        Batocera="android";        EmuDeck="android";        RetroDeck="android";        LaunchBox="Android" }
  "apple2"        = @{ RetroBat="apple2";         Batocera="apple2";         EmuDeck="apple2";         RetroDeck="apple2";         LaunchBox="Apple II" }
  "apple2gs"      = @{ RetroBat="apple2gs";       Batocera="apple2gs";       EmuDeck="apple2gs";       RetroDeck="apple2gs";       LaunchBox="Apple IIGS" }
  "arcade"        = @{ RetroBat="arcade";         Batocera="arcade";         EmuDeck="arcade";         RetroDeck="arcade";         LaunchBox="Arcade" }
  "arcadia"       = @{ RetroBat="arcadia";        Batocera="arcadia";        EmuDeck="arcadia";        RetroDeck="arcadia";        LaunchBox="Arcadia 2001" }
  "arduboy"       = @{ RetroBat="arduboy";        Batocera="arduboy";        EmuDeck="arduboy";        RetroDeck="arduboy";        LaunchBox="Arduboy" }
  "astrocde"      = @{ RetroBat="astrocde";       Batocera="astrocde";       EmuDeck="astrocde";       RetroDeck="astrocde";       LaunchBox="Bally Astrocade" }
  "atari2600"     = @{ RetroBat="atari2600";      Batocera="atari2600";      EmuDeck="atari2600";      RetroDeck="atari2600";      LaunchBox="Atari 2600" }
  "atari5200"     = @{ RetroBat="atari5200";      Batocera="atari5200";      EmuDeck="atari5200";      RetroDeck="atari5200";      LaunchBox="Atari 5200" }
  "atari7800"     = @{ RetroBat="atari7800";      Batocera="atari7800";      EmuDeck="atari7800";      RetroDeck="atari7800";      LaunchBox="Atari 7800" }
  "atari800"      = @{ RetroBat="atari800";       Batocera="atari800";       EmuDeck="atari800";       RetroDeck="atari800";       LaunchBox="Atari 8-bit Family" }
  "atarijaguar"   = @{ RetroBat="atarijaguar";    Batocera="atarijaguar";    EmuDeck="atarijaguar";    RetroDeck="atarijaguar";    LaunchBox="Atari Jaguar" }
  "atarijaguarcd" = @{ RetroBat="atarijaguarcd";  Batocera="atarijaguarcd";  EmuDeck="atarijaguarcd";  RetroDeck="atarijaguarcd";  LaunchBox="Atari Jaguar CD" }
  "atarilynx"     = @{ RetroBat="atarilynx";      Batocera="atarilynx";      EmuDeck="atarilynx";      RetroDeck="atarilynx";      LaunchBox="Atari Lynx" }
  "atarist"       = @{ RetroBat="atarist";        Batocera="atarist";        EmuDeck="atarist";        RetroDeck="atarist";        LaunchBox="Atari ST" }
  "atarixe"       = @{ RetroBat="atarixe";        Batocera="atarixe";        EmuDeck="atarixe";        RetroDeck="atarixe";        LaunchBox="Atari XE" }
  "atomiswave"    = @{ RetroBat="atomiswave";     Batocera="atomiswave";     EmuDeck="atomiswave";     RetroDeck="atomiswave";     LaunchBox="Atomiswave" }
  "bbcmicro"      = @{ RetroBat="bbcmicro";       Batocera="bbcmicro";       EmuDeck="bbcmicro";       RetroDeck="bbcmicro";       LaunchBox="BBC Micro" }
  "c16"           = @{ RetroBat="c16";            Batocera="c16";            EmuDeck="c16";            RetroDeck="c16";            LaunchBox="Commodore 16" }
  "c64"           = @{ RetroBat="c64";            Batocera="c64";            EmuDeck="c64";            RetroDeck="c64";            LaunchBox="Commodore 64" }
  "cavestory"     = @{ RetroBat="cavestory";      Batocera="cavestory";      EmuDeck="cavestory";      RetroDeck="cavestory";      LaunchBox="Cave Story" }
  "cdimono1"      = @{ RetroBat="cdimono1";       Batocera="cdimono1";       EmuDeck="cdimono1";       RetroDeck="cdimono1";       LaunchBox="Philips CD-i" }
  "cdtv"          = @{ RetroBat="cdtv";           Batocera="cdtv";           EmuDeck="cdtv";           RetroDeck="cdtv";           LaunchBox="Commodore CDTV" }
  "chailove"      = @{ RetroBat="chailove";       Batocera="chailove";       EmuDeck="chailove";       RetroDeck="chailove";       LaunchBox="ChaiLove" }
  "channelf"      = @{ RetroBat="channelf";       Batocera="channelf";       EmuDeck="channelf";       RetroDeck="channelf";       LaunchBox="Fairchild Channel F" }
  "cloud"         = @{ RetroBat="cloud";          Batocera="cloud";          EmuDeck="cloud";          RetroDeck="cloud";          LaunchBox="Cloud" }
  "coco"          = @{ RetroBat="coco";           Batocera="coco";           EmuDeck="coco";           RetroDeck="coco";           LaunchBox="Tandy Color Computer" }
  "colecovision"  = @{ RetroBat="colecovision";   Batocera="colecovision";   EmuDeck="colecovision";   RetroDeck="colecovision";   LaunchBox="ColecoVision" }
  "cps"           = @{ RetroBat="cps";            Batocera="cps";            EmuDeck="cps";            RetroDeck="cps";            LaunchBox="Capcom Play System" }
  "cps1"          = @{ RetroBat="cps1";           Batocera="cps1";           EmuDeck="cps1";           RetroDeck="cps1";           LaunchBox="Capcom CPS-1" }
  "cps2"          = @{ RetroBat="cps2";           Batocera="cps2";           EmuDeck="cps2";           RetroDeck="cps2";           LaunchBox="Capcom CPS-2" }
  "cps3"          = @{ RetroBat="cps3";           Batocera="cps3";           EmuDeck="cps3";           RetroDeck="cps3";           LaunchBox="Capcom CPS-3" }
  "crvision"      = @{ RetroBat="crvision";       Batocera="crvision";       EmuDeck="crvision";       RetroDeck="crvision";       LaunchBox="VTech CreatiVision" }
  "daphne"        = @{ RetroBat="daphne";         Batocera="daphne";         EmuDeck="daphne";         RetroDeck="daphne";         LaunchBox="Daphne (Laserdisc)" }
  "desktop"       = @{ RetroBat="desktop";        Batocera="desktop";        EmuDeck="desktop";        RetroDeck="desktop";        LaunchBox="Desktop" }
  "doom"          = @{ RetroBat="doom";           Batocera="doom";           EmuDeck="doom";           RetroDeck="doom";           LaunchBox="Doom Ports" }
  "dos"           = @{ RetroBat="dos";            Batocera="dos";            EmuDeck="dos";            RetroDeck="dos";            LaunchBox="MS-DOS" }
  "dragon32"      = @{ RetroBat="dragon32";       Batocera="dragon32";       EmuDeck="dragon32";       RetroDeck="dragon32";       LaunchBox="Dragon 32/64" }
  "dreamcast"     = @{ RetroBat="dreamcast";      Batocera="dreamcast";      EmuDeck="dreamcast";      RetroDeck="dreamcast";      LaunchBox="Sega Dreamcast" }
  "easyrpg"       = @{ RetroBat="easyrpg";        Batocera="easyrpg";        EmuDeck="easyrpg";        RetroDeck="easyrpg";        LaunchBox="EasyRPG" }
  "epic"          = @{ RetroBat="epic";           Batocera="epic";           EmuDeck="epic";           RetroDeck="epic";           LaunchBox="Epic Games" }
  "famicom"       = @{ RetroBat="famicom";        Batocera="famicom";        EmuDeck="famicom";        RetroDeck="famicom";        LaunchBox="Nintendo Famicom" }
  "fba"           = @{ RetroBat="fba";            Batocera="fba";            EmuDeck="fba";            RetroDeck="fba";            LaunchBox="Arcade" }
  "fbneo"         = @{ RetroBat="fbneo";          Batocera="fbneo";          EmuDeck="fbneo";          RetroDeck="fbneo";          LaunchBox="Arcade" }
  "fds"           = @{ RetroBat="fds";            Batocera="fds";            EmuDeck="fds";            RetroDeck="fds";            LaunchBox="Famicom Disk System" }
  "flash"         = @{ RetroBat="flash";          Batocera="flash";          EmuDeck="flash";          RetroDeck="flash";          LaunchBox="Adobe Flash" }
  "fmtowns"       = @{ RetroBat="fmtowns";        Batocera="fmtowns";        EmuDeck="fmtowns";        RetroDeck="fmtowns";        LaunchBox="Fujitsu FM Towns" }
  "gameandwatch"  = @{ RetroBat="gameandwatch";   Batocera="gameandwatch";   EmuDeck="gameandwatch";   RetroDeck="gameandwatch";   LaunchBox="Nintendo Game & Watch" }
  "gamecom"       = @{ RetroBat="gamecom";        Batocera="gamecom";        EmuDeck="gamecom";        RetroDeck="gamecom";        LaunchBox="Tiger Game.com" }
  "gamecube"      = @{ RetroBat="gamecube";       Batocera="gamecube";       EmuDeck="gamecube";       RetroDeck="gamecube";       LaunchBox="Nintendo GameCube" }
  "gamegear"      = @{ RetroBat="gamegear";       Batocera="gamegear";       EmuDeck="gamegear";       RetroDeck="gamegear";       LaunchBox="Sega Game Gear" }
  "gx4000"        = @{ RetroBat="gx4000";         Batocera="gx4000";         EmuDeck="gx4000";         RetroDeck="gx4000";         LaunchBox="Amstrad GX4000" }
  "intellivision" = @{ RetroBat="intellivision";  Batocera="intellivision";  EmuDeck="intellivision";  RetroDeck="intellivision";  LaunchBox="Mattel Intellivision" }
  "j2me"          = @{ RetroBat="j2me";           Batocera="j2me";           EmuDeck="j2me";           RetroDeck="j2me";           LaunchBox="Java 2 Micro Edition" }
  "kodi"          = @{ RetroBat="kodi";           Batocera="kodi";           EmuDeck="kodi";           RetroDeck="kodi";           LaunchBox="Kodi" }
  "lcdgames"      = @{ RetroBat="lcdgames";       Batocera="lcdgames";       EmuDeck="lcdgames";       RetroDeck="lcdgames";       LaunchBox="LCD Handhelds" }
  "lutris"        = @{ RetroBat="lutris";         Batocera="lutris";         EmuDeck="lutris";         RetroDeck="lutris";         LaunchBox="Lutris" }
  "lutro"         = @{ RetroBat="lutro";          Batocera="lutro";          EmuDeck="lutro";          RetroDeck="lutro";          LaunchBox="Lutro" }
  "macintosh"     = @{ RetroBat="macintosh";      Batocera="macintosh";      EmuDeck="macintosh";      RetroDeck="macintosh";      LaunchBox="Apple Macintosh" }
  "mame-advmame"  = @{ RetroBat="mame-advmame";   Batocera="mame-advmame";   EmuDeck="mame-advmame";   RetroDeck="mame-advmame";   LaunchBox="Arcade" }
  "mame-mame4all" = @{ RetroBat="mame-mame4all";  Batocera="mame-mame4all";  EmuDeck="mame-mame4all";  RetroDeck="mame-mame4all";  LaunchBox="Arcade" }
  "mastersystem"  = @{ RetroBat="mastersystem";   Batocera="mastersystem";   EmuDeck="mastersystem";   RetroDeck="mastersystem";   LaunchBox="Sega Master System" }
  "megacd"        = @{ RetroBat="megacd";         Batocera="megacd";         EmuDeck="megacd";         RetroDeck="megacd";         LaunchBox="Sega Mega-CD" }
  "megacdjp"      = @{ RetroBat="megacdjp";       Batocera="megacdjp";       EmuDeck="megacdjp";       RetroDeck="megacdjp";       LaunchBox="Sega Mega-CD (Japan)" }
  "megadrive"     = @{ RetroBat="megadrive";      Batocera="megadrive";      EmuDeck="genesis";        RetroDeck="genesis";        LaunchBox="Sega Genesis" }
  "megadrivejp"   = @{ RetroBat="megadrivejp";    Batocera="megadrivejp";    EmuDeck="genesis";        RetroDeck="genesis";        LaunchBox="Sega Mega Drive (JP)" }
  "megaduck"      = @{ RetroBat="megaduck";       Batocera="megaduck";       EmuDeck="megaduck";       RetroDeck="megaduck";       LaunchBox="Watara Supervision (Mega Duck)" }
  "mess"          = @{ RetroBat="mess";           Batocera="mess";           EmuDeck="mess";           RetroDeck="mess";           LaunchBox="MAME (MESS)" }
  "model2"        = @{ RetroBat="model2";         Batocera="model2";         EmuDeck="model2";         RetroDeck="model2";         LaunchBox="Sega Model 2" }
  "model3"        = @{ RetroBat="model3";         Batocera="model3";         EmuDeck="model3";         RetroDeck="model3";         LaunchBox="Sega Model 3" }
  "moonlight"     = @{ RetroBat="moonlight";      Batocera="moonlight";      EmuDeck="moonlight";      RetroDeck="moonlight";      LaunchBox="Moonlight" }
  "moto"          = @{ RetroBat="moto";           Batocera="moto";           EmuDeck="moto";           RetroDeck="moto";           LaunchBox="Motorola 680x0" }
  "msx"           = @{ RetroBat="msx";            Batocera="msx";            EmuDeck="msx";            RetroDeck="msx";            LaunchBox="Microsoft MSX" }
  "msx1"          = @{ RetroBat="msx1";           Batocera="msx1";           EmuDeck="msx1";           RetroDeck="msx1";           LaunchBox="Microsoft MSX" }
  "msx2"          = @{ RetroBat="msx2";           Batocera="msx2";           EmuDeck="msx2";           RetroDeck="msx2";           LaunchBox="Microsoft MSX2" }
  "msxturbor"     = @{ RetroBat="msxturbor";      Batocera="msxturbor";      EmuDeck="msxturbor";      RetroDeck="msxturbor";      LaunchBox="MSX Turbo R" }
  "mugen"         = @{ RetroBat="mugen";          Batocera="mugen";          EmuDeck="mugen";          RetroDeck="mugen";          LaunchBox="M.U.G.E.N" }
  "multivision"   = @{ RetroBat="multivision";    Batocera="multivision";    EmuDeck="multivision";    RetroDeck="multivision";    LaunchBox="Othello Multivision" }
  "n3ds"          = @{ RetroBat="n3ds";           Batocera="n3ds";           EmuDeck="n3ds";           RetroDeck="n3ds";           LaunchBox="Nintendo 3DS" }
  "n64dd"         = @{ RetroBat="n64dd";          Batocera="n64dd";          EmuDeck="n64dd";          RetroDeck="n64dd";          LaunchBox="Nintendo 64DD" }
  "naomi"         = @{ RetroBat="naomi";          Batocera="naomi";          EmuDeck="naomi";          RetroDeck="naomi";          LaunchBox="Sega NAOMI" }
  "naomigd"       = @{ RetroBat="naomigd";        Batocera="naomigd";        EmuDeck="naomigd";        RetroDeck="naomigd";        LaunchBox="Sega NAOMI GD-ROM" }
  "nds"           = @{ RetroBat="nds";            Batocera="nds";            EmuDeck="nds";            RetroDeck="nds";            LaunchBox="Nintendo DS" }
  "neogeo"        = @{ RetroBat="neogeo";         Batocera="neogeo";         EmuDeck="neogeo";         RetroDeck="neogeo";         LaunchBox="SNK Neo Geo" }
  "neogeocd"      = @{ RetroBat="neogeocd";       Batocera="neogeocd";       EmuDeck="neogeocd";       RetroDeck="neogeocd";       LaunchBox="Neo Geo CD" }
  "neogeocdjp"    = @{ RetroBat="neogeocdjp";     Batocera="neogeocdjp";     EmuDeck="neogeocdjp";     RetroDeck="neogeocdjp";     LaunchBox="Neo Geo CD (Japan)" }
  "ngp"           = @{ RetroBat="ngp";            Batocera="ngp";            EmuDeck="ngp";            RetroDeck="ngp";            LaunchBox="Neo Geo Pocket" }
  "ngpc"          = @{ RetroBat="ngpc";           Batocera="ngpc";           EmuDeck="ngpc";           RetroDeck="ngpc";           LaunchBox="Neo Geo Pocket Color" }
  "odyssey2"      = @{ RetroBat="odyssey2";       Batocera="odyssey2";       EmuDeck="odyssey2";       RetroDeck="odyssey2";       LaunchBox="Magnavox Odyssey²" }
  "openbor"       = @{ RetroBat="openbor";        Batocera="openbor";        EmuDeck="openbor";        RetroDeck="openbor";        LaunchBox="OpenBOR" }
  "oric"          = @{ RetroBat="oric";           Batocera="oric";           EmuDeck="oric";           RetroDeck="oric";           LaunchBox="Oric" }
  "palm"          = @{ RetroBat="palm";           Batocera="palm";           EmuDeck="palm";           RetroDeck="palm";           LaunchBox="Palm OS" }
  "pc"            = @{ RetroBat="pc";             Batocera="pc";             EmuDeck="pc";             RetroDeck="pc";             LaunchBox="Windows" }
  "pc88"          = @{ RetroBat="pc88";           Batocera="pc88";           EmuDeck="pc88";           RetroDeck="pc88";           LaunchBox="NEC PC-8801" }
  "pc98"          = @{ RetroBat="pc98";           Batocera="pc98";           EmuDeck="pc98";           RetroDeck="pc98";           LaunchBox="NEC PC-9801" }
  "pcengine"      = @{ RetroBat="pcengine";       Batocera="pcengine";       EmuDeck="pcengine";       RetroDeck="pcengine";       LaunchBox="NEC PC Engine" }
  "pcenginecd"    = @{ RetroBat="pcenginecd";     Batocera="pcenginecd";     EmuDeck="pcenginecd";     RetroDeck="pcenginecd";     LaunchBox="NEC PC Engine CD-ROM²" }
  "pcfx"          = @{ RetroBat="pcfx";           Batocera="pcfx";           EmuDeck="pcfx";           RetroDeck="pcfx";           LaunchBox="NEC PC-FX" }
  "pico8"         = @{ RetroBat="pico8";          Batocera="pico8";          EmuDeck="pico8";          RetroDeck="pico8";          LaunchBox="PICO-8" }
  "pokemini"      = @{ RetroBat="pokemini";       Batocera="pokemini";       EmuDeck="pokemini";       RetroDeck="pokemini";       LaunchBox="Pokemon Mini" }
  "ports"         = @{ RetroBat="ports";          Batocera="ports";          EmuDeck="ports";          RetroDeck="ports";          LaunchBox="Ports" }
  "primehacks"    = @{ RetroBat="primehacks";     Batocera="primehacks";     EmuDeck="primehacks";     RetroDeck="primehacks";     LaunchBox="PrimeHack" }
  "ps3"           = @{ RetroBat="ps3";            Batocera="ps3";            EmuDeck="ps3";            RetroDeck="ps3";            LaunchBox="Sony PlayStation 3" }
  "ps4"           = @{ RetroBat="ps4";            Batocera="ps4";            EmuDeck="ps4";            RetroDeck="ps4";            LaunchBox="Sony PlayStation 4" }
  "pv1000"        = @{ RetroBat="pv1000";         Batocera="pv1000";         EmuDeck="pv1000";         RetroDeck="pv1000";         LaunchBox="Casio PV-1000" }
  "quake"         = @{ RetroBat="quake";          Batocera="quake";          EmuDeck="quake";          RetroDeck="quake";          LaunchBox="Quake" }
  "remoteplay"    = @{ RetroBat="remoteplay";     Batocera="remoteplay";     EmuDeck="remoteplay";     RetroDeck="remoteplay";     LaunchBox="Remote Play" }
  "samcoupe"      = @{ RetroBat="samcoupe";       Batocera="samcoupe";       EmuDeck="samcoupe";       RetroDeck="samcoupe";       LaunchBox="SAM Coupé" }
  "satellaview"   = @{ RetroBat="satellaview";    Batocera="satellaview";    EmuDeck="satellaview";    RetroDeck="satellaview";    LaunchBox="Nintendo Satellaview" }
  "saturn"        = @{ RetroBat="saturn";         Batocera="saturn";         EmuDeck="saturn";         RetroDeck="saturn";         LaunchBox="Sega Saturn" }
  "saturnjp"      = @{ RetroBat="saturnjp";       Batocera="saturnjp";       EmuDeck="saturnjp";       RetroDeck="saturnjp";       LaunchBox="Sega Saturn (Japan)" }
  "scummvm"       = @{ RetroBat="scummvm";        Batocera="scummvm";        EmuDeck="scummvm";        RetroDeck="scummvm";        LaunchBox="ScummVM" }
  "sega32x"       = @{ RetroBat="sega32x";        Batocera="sega32x";        EmuDeck="sega32x";        RetroDeck="sega32x";        LaunchBox="Sega 32X" }
  "sega32xjp"     = @{ RetroBat="sega32xjp";      Batocera="sega32xjp";      EmuDeck="sega32xjp";      RetroDeck="sega32xjp";      LaunchBox="Sega 32X (Japan)" }
  "sega32xna"     = @{ RetroBat="sega32xna";      Batocera="sega32xna";      EmuDeck="sega32xna";      RetroDeck="sega32xna";      LaunchBox="Sega 32X (North America)" }
  "segacd"        = @{ RetroBat="segacd";         Batocera="segacd";         EmuDeck="segacd";         RetroDeck="segacd";         LaunchBox="Sega CD" }
  "sfc"           = @{ RetroBat="sfc";            Batocera="sfc";            EmuDeck="sfc";            RetroDeck="sfc";            LaunchBox="Super Famicom" }
  "sg-1000"       = @{ RetroBat="sg-1000";        Batocera="sg-1000";        EmuDeck="sg-1000";        RetroDeck="sg-1000";        LaunchBox="Sega SG-1000" }
  "sgb"           = @{ RetroBat="sgb";            Batocera="sgb";            EmuDeck="sgb";            RetroDeck="sgb";            LaunchBox="Super Game Boy" }
  "sneshd"        = @{ RetroBat="sneshd";         Batocera="sneshd";         EmuDeck="sneshd";         RetroDeck="sneshd";         LaunchBox="Super Nintendo (HD Packs)" }
  "snesna"        = @{ RetroBat="snesna";         Batocera="snesna";         EmuDeck="snesna";         RetroDeck="snesna";         LaunchBox="Super Nintendo (North America)" }
  "solarus"       = @{ RetroBat="solarus";        Batocera="solarus";        EmuDeck="solarus";        RetroDeck="solarus";        LaunchBox="Solarus" }
  "spectravideo"  = @{ RetroBat="spectravideo";   Batocera="spectravideo";   EmuDeck="spectravideo";   RetroDeck="spectravideo";   LaunchBox="Spectravideo" }
  "steam"         = @{ RetroBat="steam";          Batocera="steam";          EmuDeck="steam";          RetroDeck="steam";          LaunchBox="Steam" }
  "stratagus"     = @{ RetroBat="stratagus";      Batocera="stratagus";      EmuDeck="stratagus";      RetroDeck="stratagus";      LaunchBox="Stratagus" }
  "sufami"        = @{ RetroBat="sufami";         Batocera="sufami";         EmuDeck="sufami";         RetroDeck="sufami";         LaunchBox="Sufami Turbo" }
  "supergrafx"    = @{ RetroBat="supergrafx";     Batocera="supergrafx";     EmuDeck="supergrafx";     RetroDeck="supergrafx";     LaunchBox="NEC SuperGrafx" }
  "supervision"   = @{ RetroBat="supervision";    Batocera="supervision";    EmuDeck="supervision";    RetroDeck="supervision";    LaunchBox="Watara Supervision" }
  "switch"        = @{ RetroBat="switch";         Batocera="switch";         EmuDeck="switch";         RetroDeck="switch";         LaunchBox="Nintendo Switch" }
  "symbian"       = @{ RetroBat="symbian";        Batocera="symbian";        EmuDeck="symbian";        RetroDeck="symbian";        LaunchBox="Symbian" }
  "tanodragon"    = @{ RetroBat="tanodragon";     Batocera="tanodragon";     EmuDeck="tanodragon";     RetroDeck="tanodragon";     LaunchBox="Tandy TRS-80 Dragon" }
  "tg-cd"         = @{ RetroBat="tg-cd";          Batocera="tg-cd";          EmuDeck="tg-cd";          RetroDeck="tg-cd";          LaunchBox="TurboGrafx-CD" }
  "tg16"          = @{ RetroBat="tg16";           Batocera="tg16";           EmuDeck="tg16";           RetroDeck="tg16";           LaunchBox="TurboGrafx-16" }
  "ti99"          = @{ RetroBat="ti99";           Batocera="ti99";           EmuDeck="ti99";           RetroDeck="ti99";           LaunchBox="TI-99/4A" }
  "tic80"         = @{ RetroBat="tic80";          Batocera="tic80";          EmuDeck="tic80";          RetroDeck="tic80";          LaunchBox="TIC-80" }
  "to8"           = @{ RetroBat="to8";            Batocera="to8";            EmuDeck="to8";            RetroDeck="to8";            LaunchBox="Thomson TO8" }
  "trs-80"        = @{ RetroBat="trs-80";         Batocera="trs-80";         EmuDeck="trs-80";         RetroDeck="trs-80";         LaunchBox="TRS-80" }
  "uzebox"        = @{ RetroBat="uzebox";         Batocera="uzebox";         EmuDeck="uzebox";         RetroDeck="uzebox";         LaunchBox="Uzebox" }
  "vectrex"       = @{ RetroBat="vectrex";        Batocera="vectrex";        EmuDeck="vectrex";        RetroDeck="vectrex";        LaunchBox="GCE Vectrex" }
  "vic20"         = @{ RetroBat="vic20";          Batocera="vic20";          EmuDeck="vic20";          RetroDeck="vic20";          LaunchBox="Commodore VIC-20" }
  "videopac"      = @{ RetroBat="videopac";       Batocera="videopac";       EmuDeck="videopac";       RetroDeck="videopac";       LaunchBox="Philips Videopac" }
  "virtualboy"    = @{ RetroBat="virtualboy";     Batocera="virtualboy";     EmuDeck="virtualboy";     RetroDeck="virtualboy";     LaunchBox="Nintendo Virtual Boy" }
  "vsmile"        = @{ RetroBat="vsmile";         Batocera="vsmile";         EmuDeck="vsmile";         RetroDeck="vsmile";         LaunchBox="VTech V.Smile" }
  "wasm4"         = @{ RetroBat="wasm4";          Batocera="wasm4";          EmuDeck="wasm4";          RetroDeck="wasm4";          LaunchBox="WASM-4" }
  "wii"           = @{ RetroBat="wii";            Batocera="wii";            EmuDeck="wii";            RetroDeck="wii";            LaunchBox="Nintendo Wii" }
  "wiiu"          = @{ RetroBat="wiiu";           Batocera="wiiu";           EmuDeck="wiiu";           RetroDeck="wiiu";           LaunchBox="Nintendo Wii U" }
  "windows"       = @{ RetroBat="windows";        Batocera="windows";        EmuDeck="windows";        RetroDeck="windows";        LaunchBox="Windows" }
  "wonderswan"    = @{ RetroBat="wonderswan";     Batocera="wonderswan";     EmuDeck="wonderswan";     RetroDeck="wonderswan";     LaunchBox="Bandai WonderSwan" }
  "wonderswancolor"=@{ RetroBat="wonderswancolor";Batocera="wonderswancolor";EmuDeck="wonderswancolor";RetroDeck="wonderswancolor";LaunchBox="Bandai WonderSwan Color" }
  "x1"            = @{ RetroBat="x1";             Batocera="x1";             EmuDeck="x1";             RetroDeck="x1";             LaunchBox="Sharp X1" }
  "x68000"        = @{ RetroBat="x68000";         Batocera="x68000";         EmuDeck="x68000";         RetroDeck="x68000";         LaunchBox="Sharp X68000" }
  "xbox"          = @{ RetroBat="xbox";           Batocera="xbox";           EmuDeck="xbox";           RetroDeck="xbox";           LaunchBox="Microsoft Xbox" }
  "xbox360"       = @{ RetroBat="xbox360";        Batocera="xbox360";        EmuDeck="xbox360";        RetroDeck="xbox360";        LaunchBox="Microsoft Xbox 360" }
  "xbla"          = @{ RetroBat="xbla";           Batocera="xbla";           EmuDeck="xbla";           RetroDeck="xbla";           LaunchBox="Xbox Live Arcade" }
  "zmachine"      = @{ RetroBat="zmachine";       Batocera="zmachine";       EmuDeck="zmachine";       RetroDeck="zmachine";       LaunchBox="Z-Machine (Infocom)" }
  "zx81"          = @{ RetroBat="zx81";           Batocera="zx81";           EmuDeck="zx81";           RetroDeck="zx81";           LaunchBox="Sinclair ZX81" }
  "zxspectrum"    = @{ RetroBat="zxspectrum";     Batocera="zxspectrum";     EmuDeck="zxspectrum";     RetroDeck="zxspectrum";     LaunchBox="Sinclair ZX Spectrum" }
}


$CanonicalIndex = @{}
foreach ($canon in $SystemCanonical.Keys) {
  foreach ($fe in $SystemCanonical[$canon].Keys) {
    $n = $SystemCanonical[$canon][$fe]
    if ($n) { $CanonicalIndex["$fe|$($n.ToLowerInvariant())"] = $canon }
  }
}

$CanonicalImageTypes = @('screenshot','marquee','boxfront')
$CanonicalVideoType  = 'video'

function To-Canonical {
  param([string]$frontend, [string]$actualName)
  if (-not $actualName) { return $null }
  $key = "$frontend|$($actualName.ToLowerInvariant())"
  if ($CanonicalIndex.ContainsKey($key)) { return $CanonicalIndex[$key] }
  $norm = ($actualName -replace '[\s_-]+','').ToLowerInvariant()
  foreach ($canon in $SystemCanonical.Keys) {
    foreach ($fe in $SystemCanonical[$canon].Keys) {
      $n = $SystemCanonical[$canon][$fe]; if (-not $n) { continue }
      if ((($n -replace '[\s_-]+','').ToLowerInvariant()) -eq $norm) { return $canon }
    }
  }
  return $null
}

function From-Canonical {
  param([string]$frontend, [string]$canonical)
  if ($SystemCanonical.ContainsKey($canonical) -and $SystemCanonical[$canonical].ContainsKey($frontend)) {
    return $SystemCanonical[$canonical][$frontend]
  }
  return $null
}

# ---------- Destination systems to scan (list only) ----------
function Get-Systems {
    param([string]$frontend)
    switch ($frontend) {
        'RetroBat' {
            ,@("3do","ags","amiga","amiga1200","amiga600","amigacd32","amstradcpc","android","apple2","apple2gs","arcade","arcadia","arduboy","astrocde","atari2600","atari5200","atari7800","atari800","atarijaguar","atarijaguarcd","atarilynx","atarist","atarixe","atomiswave","bbcmicro","c16","c64","cavestory","cdimono1","cdtv","chailove","channelf","cloud","coco","colecovision","cps","cps1","cps2","cps3","crvision","daphne","desktop","doom","dos","dragon32","dreamcast","easyrpg","epic","famicom","fba","fbneo","fds","flash","fmtowns","gameandwatch","gamecom","gamegear","gb","gba","gbc","gamecube","gx4000","intellivision","j2me","kodi","lcdgames","lutris","lutro","macintosh","mame","mame-advmame","mame-mame4all","mastersystem","megacd","megacdjp","megadrive","megadrivejp","megaduck","mess","model2","model3","moonlight","moto","msx","msx1","msx2","msxturbor","mugen","multivision","n3ds","n64","n64dd","naomi","naomigd","nds","neogeo","neogeocd","neogeocdjp","nes","ngp","ngpc","odyssey2","openbor","oric","palm","pc","pc88","pc98","pcengine","pcenginecd","pcfx","pico8","pokemini","ports","primehacks","ps2","ps3","ps4","psp","psvita","psx","pv1000","quake","remoteplay","samcoupe","satellaview","saturn","saturnjp","scummvm","sega32x","sega32xjp","sega32xna","segacd","sfc","sg-1000","sgb","snes","sneshd","snesna","solarus","spectravideo","steam","stratagus","sufami","supergrafx","supervision","switch","symbian","tanodragon","tg-cd","tg16","ti99","tic80","to8","trs-80","uzebox","vectrex","vic20","videopac","virtualboy","vsmile","wasm4","wii","wiiu","windows","wonderswan","wonderswancolor","x1","x68000","xbox","xbox360","xbla","zmachine","zx81","zxspectrum")
        }
        'Batocera'  { ,@('nes','snes','megadrive','gba','n64') }
        'EmuDeck'   { ,@('nes','snes','genesis','gba','n64') }
        'RetroDeck' { ,@('nes','snes','genesis','gba','n64') }
        'LaunchBox' { ,@('Nintendo Entertainment System','Super Nintendo Entertainment System','Sega Genesis','Nintendo Game Boy Advance','Nintendo 64','Arcade') }
        default     { ,@() }
    }
}

# ---------- Where to scan ROMs for each frontend ----------
function Get-LocalSystemRoot {
    param([string]$frontend, [string]$localRoot, [string]$systemName)

    switch ($frontend) {
        'LaunchBox' {
            return (Join-Path (Join-Path $localRoot 'Games') $systemName)
        }
        default {
            return (Join-Path $localRoot $systemName)
        }
    }
}

# ---------- Source Schemas (where media comes from) ----------
function Get-SourceSchema {
    param([string]$frontend)

    switch ($frontend) {
        'LaunchBox' {
            return @{
                SourceMode   = 'Centralized'   # Images\<Platform>\<Subfolder>, Videos\<Platform>
                ImageTypes   = @('screenshot','marquee','boxfront')
                VideoPresent = $true
                Images       = @{
                    'screenshot' = @{ MatchMode='Plain';  Suffix=$null; Folder=$null; Subfolders=@('Screenshots') }
                    'marquee'    = @{ MatchMode='Plain';  Suffix=$null; Folder=$null; Subfolders=@('Marquees') }
                    'boxfront'   = @{ MatchMode='Plain';  Suffix=$null; Folder=$null; Subfolders=@('Covers','Box - Front') }
                }
                Video        = @{ MatchMode='Plain'; Suffix=$null; Folder=$null; Subfolders=@() }
            }
        }

        'EmuDeck' {
            # <remoteRoot>\<system>\{screenshots|marquees|covers|videos}
            return @{
                SourceMode   = 'Flat'
                ImageTypes   = @('screenshot','marquee','boxfront')
                VideoPresent = $true
                Images       = @{
                    'screenshot' = @{ MatchMode='Suffix'; Suffix='image';   Folder='screenshots'; Subfolders=$null }
                    'marquee'    = @{ MatchMode='Suffix'; Suffix='marquee'; Folder='marquees';    Subfolders=$null }
                    'boxfront'   = @{ MatchMode='Suffix'; Suffix='thumb';   Folder='covers';      Subfolders=$null }
                }
                Video        = @{ MatchMode='Suffix'; Suffix='video'; Folder='videos'; Subfolders=$null }
            }
        }

        'RetroDeck' {
            # <remoteRoot>\<system>\{screenshots|marquees|covers|videos}
            return @{
                SourceMode   = 'Flat'
                ImageTypes   = @('screenshot','marquee','boxfront')
                VideoPresent = $true
                Images       = @{
                    'screenshot' = @{ MatchMode='Suffix'; Suffix='image';   Folder='screenshots'; Subfolders=$null }
                    'marquee'    = @{ MatchMode='Suffix'; Suffix='marquee'; Folder='marquees';    Subfolders=$null }
                    'boxfront'   = @{ MatchMode='Suffix'; Suffix='thumb';   Folder='covers';      Subfolders=$null }
                }
                Video        = @{ MatchMode='Suffix'; Suffix='video'; Folder='videos'; Subfolders=$null }
            }
        }

        default {
            # Flat <system>\images|videos
            return @{
                SourceMode   = 'Flat'
                ImageTypes   = @('screenshot','marquee','boxfront')
                VideoPresent = $true
                Images       = @{
                    'screenshot' = @{ MatchMode='Suffix'; Suffix='image';   Folder='images'; Subfolders=$null }
                    'marquee'    = @{ MatchMode='Suffix'; Suffix='marquee'; Folder='images'; Subfolders=$null }
                    'boxfront'   = @{ MatchMode='Suffix'; Suffix='thumb';   Folder='images'; Subfolders=$null }
                }
                Video        = @{ MatchMode='Suffix'; Suffix='video'; Folder='videos'; Subfolders=$null }
            }
        }
    }
}

# ---------- Destination Schemas (where we write media to) ----------
function Get-DestSchema {
    param([string]$frontend, [string]$localSystemRoot, [string]$localOverrideRoot)

    # Compute system name from the localSystemRoot (works for RetroBat-style ROM roots and LB Games\<Platform>)
    $systemName = Split-Path $localSystemRoot -Leaf

    switch ($frontend) {
        'LaunchBox' {
            $gamesFolder = Split-Path $localSystemRoot -Parent
            $lbRoot      = Split-Path $gamesFolder -Parent
            $platform    = $systemName

            return @{
                Mode            = 'Centralized'
                ImagesRoot      = $null
                VideosRoot      = $null
                ImagesBase      = Join-Path (Join-Path $lbRoot 'Images') $platform
                VideosBase      = Join-Path (Join-Path $lbRoot 'Videos') $platform
                ImagesInRomRoot = $false
                ImageTypes      = @('screenshot','marquee','boxfront')
                Images          = @{
                    'screenshot' = @{ FilePattern='{rom}{ext}'; Suffix=$null; Subfolder='Screenshots' }
                    'marquee'    = @{ FilePattern='{rom}{ext}'; Suffix=$null; Subfolder='Marquees'   }
                    'boxfront'   = @{ FilePattern='{rom}{ext}'; Suffix=$null; Subfolder='Covers'     }
                }
                VideoPresent    = $true
                Video           = @{ FilePattern='{rom}{ext}'; Suffix=$null }
            }
        }

                'EmuDeck' {
            if ([string]::IsNullOrWhiteSpace($localOverrideRoot)) {
                throw "EmuDeck destination requires 'Optional Local Media Path' (the base you will copy to Linux later)."
            }
            $base   = Join-Path $localOverrideRoot 'downloaded_media'
            $sysBase = Join-Path $base $systemName

            return @{
                Mode            = 'Centralized'
                ImagesRoot      = $null
                VideosRoot      = $null
                ImagesBase      = $sysBase
                VideosBase      = $sysBase
                ImagesInRomRoot = $false
                ImageTypes      = @('screenshot','marquee','boxfront')
                Images          = @{
                    # NOTE: no suffix, plain file name
                    'screenshot' = @{ FilePattern='{rom}{ext}'; Suffix=$null; Subfolder='screenshots' }
                    'marquee'    = @{ FilePattern='{rom}{ext}'; Suffix=$null; Subfolder='marquees'    }
                    'boxfront'   = @{ FilePattern='{rom}{ext}'; Suffix=$null; Subfolder='covers'      }
                }
                VideoPresent    = $true
                # NOTE: no suffix, and put into 'videos' subfolder
                Video           = @{ FilePattern='{rom}{ext}'; Suffix=$null; Subfolder='videos' }
            }
        }

        'RetroDeck' {
            if ([string]::IsNullOrWhiteSpace($localOverrideRoot)) {
                throw "RetroDeck destination requires 'Optional Local Media Path' (the base you will copy to Linux later)."
            }
            $base   = Join-Path $localOverrideRoot 'downloaded_media'
            $sysBase = Join-Path $base $systemName

            return @{
                Mode            = 'Centralized'
                ImagesRoot      = $null
                VideosRoot      = $null
                ImagesBase      = $sysBase
                VideosBase      = $sysBase
                ImagesInRomRoot = $false
                ImageTypes      = @('screenshot','marquee','boxfront')
                Images          = @{
                    # NOTE: no suffix, plain file name
                    'screenshot' = @{ FilePattern='{rom}{ext}'; Suffix=$null; Subfolder='screenshots' }
                    'marquee'    = @{ FilePattern='{rom}{ext}'; Suffix=$null; Subfolder='marquees'    }
                    'boxfront'   = @{ FilePattern='{rom}{ext}'; Suffix=$null; Subfolder='covers'      }
                }
                VideoPresent    = $true
                # NOTE: no suffix, and put into 'videos' subfolder
                Video           = @{ FilePattern='{rom}{ext}'; Suffix=$null; Subfolder='videos' }
            }
        }

        default {
            # Flat frontends (RetroBat/Batocera/etc.)
            $images = Join-Path $localSystemRoot 'images'
            $videos = Join-Path $localSystemRoot 'videos'
            return @{
                Mode            = 'Flat'
                ImagesRoot      = $images
                VideosRoot      = $videos
                ImagesBase      = $null
                VideosBase      = $null
                ImagesInRomRoot = $false
                ImageTypes      = @('screenshot','marquee','boxfront')
                Images          = @{
                    'screenshot' = @{ FilePattern='{rom}-{suffix}{ext}'; Suffix='image'   }
                    'marquee'    = @{ FilePattern='{rom}-{suffix}{ext}'; Suffix='marquee' }
                    'boxfront'   = @{ FilePattern='{rom}-{suffix}{ext}'; Suffix='thumb'   }
                }
                VideoPresent    = $true
                Video           = @{ FilePattern='{rom}-{suffix}{ext}'; Suffix='video' }
            }
        }
    }
}


# ---------- Source path builder ----------
function Get-SourcePaths {
    param(
        [string]$frontend,
        [string]$remoteRoot,
        [string]$systemName,
        [hashtable]$schema
    )

    switch ($schema.SourceMode) {
        'Centralized' {
            return @{
                Mode        = 'Centralized'
                ImagesBase  = Join-Path (Join-Path $remoteRoot 'Images') $systemName
                VideosBase  = Join-Path (Join-Path $remoteRoot 'Videos') $systemName
                RemoteRoot  = $remoteRoot
                SystemName  = $systemName
            }
        }
        default {
            $root = Join-Path $remoteRoot $systemName
            return @{
                Mode        = 'Flat'
                RemoteRoot  = $remoteRoot
                SystemRoot  = $root
                SystemName  = $systemName
            }
        }
    }
}

# ---------- Helpers ----------
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

function Ensure-Folder {
    param ($path)
    if (-not (Test-Path -LiteralPath $path)) {
        New-Item -ItemType Directory -Force -Path $path | Out-Null
    }
}

function Build-DestFilename {
    param([string]$pattern, [string]$romBase, [string]$ext, [string]$suffix)
    $name = $pattern.Replace('{rom}', $romBase).Replace('{ext}', $ext)
    if ($suffix) { $name = $name.Replace('{suffix}', $suffix) } else { $name = $name.Replace('{suffix}', '') }
    return $name
}

# media report labels
function Get-MissingLabel {
    param(
        [hashtable]$destSchema,
        [string]$type,        # 'screenshot' | 'marquee' | 'boxfront'
        [bool]$isVideo = $false
    )

    if ($isVideo) {
        if ($destSchema.Mode -eq 'Centralized') {
            if ($destSchema.ContainsKey('Video') -and $destSchema.Video.ContainsKey('Subfolder') -and $destSchema.Video['Subfolder']) {
                return $destSchema.Video['Subfolder']   # e.g. 'videos' (EmuDeck/RetroDeck)
            }
        }
        if ($destSchema.ContainsKey('Video') -and $destSchema.Video.ContainsKey('Suffix') -and $destSchema.Video['Suffix']) {
            return $destSchema.Video['Suffix']           # e.g. 'video' (RetroBat-style)
        }
        return 'video'
    }

    # Images
    if ($destSchema.Mode -eq 'Centralized') {
        if ($destSchema.Images.ContainsKey($type)) {
            $rule = $destSchema.Images[$type]
            if ($rule -and $rule.ContainsKey('Subfolder') -and $rule['Subfolder']) {
                return $rule['Subfolder']                # e.g. 'covers' / 'screenshots' / 'marquees'
            }
        }
    }

    if ($destSchema.Images.ContainsKey($type)) {
        $rule = $destSchema.Images[$type]
        if ($rule -and $rule.ContainsKey('Suffix') -and $rule['Suffix']) {
            return $rule['Suffix']                       # e.g. 'thumb' / 'image' / 'marquee' (RetroBat-style)
        }
    }

    # Fallback: map canonical -> nice plural folder names
    switch ($type) {
        'boxfront'   { return 'covers' }
        'marquee'    { return 'marquees' }
        'screenshot' { return 'screenshots' }
        default      { return $type }
    }
}


# ---------- Engine ----------
function Sync-Media {
    param(
        [string]$localRoot,
        [string]$remoteRoot,
        [string]$FrontendUsing,
        [string]$FrontendFrom,
        [bool]$SyncImages,
        [bool]$SyncVideos,
        [System.Windows.Forms.ProgressBar]$ProgressBar
    )

    if ($ProgressBar) { $ProgressBar.Value = 5 }

    $systems = Get-Systems $FrontendUsing
    $existingSystems = @()
    foreach ($s in $systems) {
        $probe = Get-LocalSystemRoot -frontend $FrontendUsing -localRoot $localRoot -systemName $s
        if (Test-Path -LiteralPath $probe) { $existingSystems += $s }
    }
    if ($existingSystems.Count -eq 0) {
        Write-Log "No known system folders found under $localRoot for $FrontendUsing."
        return
    }

    $schemaFrom = Get-SourceSchema $FrontendFrom
    $missingMedia = @{}
    $perSystemStep = [math]::Max([math]::Floor(90 / [math]::Max($existingSystems.Count,1)), 1)
    $progressVal = 5

    foreach ($system in $existingSystems) {
        Write-Log "Processing [$system]..."

        $localSystemRoot = Get-LocalSystemRoot -frontend $FrontendUsing -localRoot $localRoot -systemName $system
        $canonical       = To-Canonical $FrontendUsing $system

        $sourceSystem = $null
        if ($canonical) {
            $sourceSystem = From-Canonical $FrontendFrom $canonical
        } else {
            $sourceSystem = $system
        }

        if (-not $sourceSystem) {
            Write-Log "  No mapping for '$system' ($FrontendUsing -> $FrontendFrom). Skipping."
            $progressVal = [math]::Min($progressVal + $perSystemStep, 95)
            if ($ProgressBar) { $ProgressBar.Value = $progressVal }
            continue
        }

        $destSchema = Get-DestSchema -frontend $FrontendUsing -localSystemRoot $localSystemRoot -localOverrideRoot $localMediaPath

        # Ensure destination folders (flat or centralized)
        if ($destSchema.Mode -eq 'Centralized') {
            if ($destSchema.ImagesBase) { Ensure-Folder $destSchema.ImagesBase }
            if ($destSchema.VideosBase) { Ensure-Folder $destSchema.VideosBase }
            foreach ($t in $destSchema.ImageTypes) {
                $sub = $destSchema.Images[$t]['Subfolder']
                if ($sub) { Ensure-Folder (Join-Path $destSchema.ImagesBase $sub) }
            }
        } else {
            Ensure-Folder $destSchema.ImagesRoot
            Ensure-Folder $destSchema.VideosRoot
        }

        $srcPaths = Get-SourcePaths -frontend $FrontendFrom -remoteRoot $remoteRoot -systemName $sourceSystem -schema $schemaFrom

        $romFiles = Get-ChildItem -LiteralPath $localSystemRoot | Where-Object { -not $_.PSIsContainer -or $_.Extension -eq ".ps3" }
        $romDict  = Get-RomDict $romFiles

        # Intersection of types supported by source & destination
        $imageTypesToTry = @()
        if ($SyncImages) {
            foreach ($t in $CanonicalImageTypes) {
                if ($schemaFrom.ImageTypes -contains $t -and $destSchema.ImageTypes -contains $t) { $imageTypesToTry += $t }
            }
        }
        $doVideos = ($SyncVideos -and $schemaFrom.VideoPresent -and $destSchema.VideoPresent)

        # Source discovery caches (per type)
        $imgPoolByType = @{}  # type -> files[]
        if ($SyncImages) {
            foreach ($t in $imageTypesToTry) {
                $imgRule = $schemaFrom.Images[$t]
                if ($srcPaths.Mode -eq 'Centralized') {
                    $collected = @()
                    foreach ($sub in $imgRule['Subfolders']) {
                        $p = Join-Path $srcPaths.ImagesBase $sub
                        if (Test-Path -LiteralPath $p) {
                            $files = Get-ChildItem -LiteralPath $p -File
                            $collected += $files
                        }
                    }
                    $imgPoolByType[$t] = $collected
                } else {
                    $folderName = 'images'
                    if ($imgRule.ContainsKey('Folder') -and $imgRule['Folder']) { $folderName = $imgRule['Folder'] }
                    $folder = Join-Path $srcPaths.SystemRoot $folderName

                    $files = @()
                    if (Test-Path -LiteralPath $folder) {
                        $files = Get-ChildItem -LiteralPath $folder -File
                    }
                    $imgPoolByType[$t] = $files
                }
            }
        }

        $videoPool = @()
        if ($doVideos) {
            $vRule = $schemaFrom.Video
            if ($srcPaths.Mode -eq 'Centralized') {
                $vBase = $srcPaths.VideosBase
                if (Test-Path -LiteralPath $vBase) {
                    $videoPool = Get-ChildItem -LiteralPath $vBase -File
                } else {
                    $videoPool = @()
                }
            } else {
                $vFolderName = 'videos'
                if ($vRule.ContainsKey('Folder') -and $vRule['Folder']) { $vFolderName = $vRule['Folder'] }
                $vFolder = Join-Path $srcPaths.SystemRoot $vFolderName

                if (Test-Path -LiteralPath $vFolder) {
                    $videoPool = Get-ChildItem -LiteralPath $vFolder -File
                } else {
                    $videoPool = @()
                }
            }
        }

        $romCount   = [math]::Max($romDict.Count, 1)
        $perRomBump = [math]::Max([math]::Floor($perSystemStep / $romCount), 1)

        foreach ($romBase in $romDict.Keys) {
            $clean = $romDict[$romBase]
            $missing = @()

            # ----- IMAGES -----
            foreach ($t in $imageTypesToTry) {
                $pool    = $imgPoolByType[$t]
                $imgRule = $schemaFrom.Images[$t]
                $match   = $null

                $matchMode = $imgRule['MatchMode']
                if ($matchMode -eq 'Plain') {
                    $match = $pool | Where-Object { (Get-CleanName $_.BaseName) -eq $clean } | Select-Object -First 1
                    if (-not $match -and $imgRule['Suffix']) {
                        $match = $pool | Where-Object {
                            ($_.BaseName -match ("-" + $imgRule['Suffix'] + "$")) -and (Get-CleanName ($_.BaseName -replace ("-" + $imgRule['Suffix'] + "$"),"")) -eq $clean
                        } | Select-Object -First 1
                    }
                } else {
                    $match = $pool | Where-Object {
                        ($_.BaseName -match ("-" + $imgRule['Suffix'] + "$")) -and (Get-CleanName ($_.BaseName -replace ("-" + $imgRule['Suffix'] + "$"),"")) -eq $clean
                    } | Select-Object -First 1
                    if (-not $match) {
                        $match = $pool | Where-Object { (Get-CleanName $_.BaseName) -eq $clean } | Select-Object -First 1
                    }
                }

                if ($match) {
                    $destRule  = $destSchema.Images[$t]
                    $destName  = Build-DestFilename -pattern $destRule['FilePattern'] -romBase $romBase -ext $match.Extension -suffix $destRule['Suffix']

                    if ($destSchema.Mode -eq 'Centralized') {
                        $destFolder = Join-Path $destSchema.ImagesBase $destRule['Subfolder']
                        Ensure-Folder $destFolder
                        $destPath   = Join-Path $destFolder $destName
                    } else {
                        if ($destSchema.ImagesInRomRoot) {
                            $destPath = Join-Path $localSystemRoot $destName
                        } else {
                            $destPath = Join-Path $destSchema.ImagesRoot $destName
                        }
                    }

                    if (-not (Test-Path -LiteralPath $destPath)) { Copy-Item -LiteralPath $match.FullName -Destination $destPath }
                } else {
                    $missing += (Get-MissingLabel -destSchema $destSchema -type $t)
                }

            }

            # ----- VIDEO -----
            if ($doVideos) {
                $vRule  = $schemaFrom.Video
                $vMatch = $null
                $vMatchMode = $vRule['MatchMode']

                if ($vMatchMode -eq 'Plain') {
                    $vMatch = $videoPool | Where-Object { (Get-CleanName $_.BaseName) -eq $clean } | Select-Object -First 1
                    if (-not $vMatch -and $vRule['Suffix']) {
                        $vMatch = $videoPool | Where-Object {
                            ($_.BaseName -match ("-" + $vRule['Suffix'] + "$")) -and (Get-CleanName ($_.BaseName -replace ("-" + $vRule['Suffix'] + "$"),"")) -eq $clean
                        } | Select-Object -First 1
                    }
                } else {
                    $vMatch = $videoPool | Where-Object {
                        ($_.BaseName -match ("-" + $vRule['Suffix'] + "$")) -and (Get-CleanName ($_.BaseName -replace ("-" + $vRule['Suffix'] + "$"),"")) -eq $clean
                    } | Select-Object -First 1
                    if (-not $vMatch) {
                        $vMatch = $videoPool | Where-Object { (Get-CleanName $_.BaseName) -eq $clean } | Select-Object -First 1
                    }
                }

                if ($vMatch) {
                    $destV     = $destSchema.Video
                    $videoName = Build-DestFilename -pattern $destV['FilePattern'] -romBase $romBase -ext $vMatch.Extension -suffix $destV['Suffix']
                    $videoDest = $null
                    if ($destSchema.Mode -eq 'Centralized') {
                        $vFolder = $destSchema.VideosBase
                        $vSub = $destSchema.Video['Subfolder']
                        if ($vSub) { $vFolder = Join-Path $vFolder $vSub; Ensure-Folder $vFolder }
                        $videoDest = Join-Path $vFolder $videoName
                    } else {
                        $videoDest = Join-Path $destSchema.VideosRoot $videoName
                    }

                    if (-not (Test-Path -LiteralPath $videoDest)) { Copy-Item -LiteralPath $vMatch.FullName -Destination $videoDest }
                } else {
                    $missing += (Get-MissingLabel -destSchema $destSchema -type 'video' -isVideo $true)
                }

            }

            if ($missing.Count -gt 0) {
                if (-not $missingMedia.ContainsKey($system)) { $missingMedia[$system] = @{} }
                $missingMedia[$system][$romBase] = $missing
            }

            if ($ProgressBar) {
                $progressVal = [math]::Min($progressVal + $perRomBump, 95)
                $ProgressBar.Value = $progressVal
            }
        }

        if ($ProgressBar) {
            $progressVal = [math]::Min($progressVal - ($perRomBump * $romCount) + $perSystemStep, 95)
            $ProgressBar.Value = $progressVal
        }
    }

    # Missing-media report (dest-side terminology)
    $EnableDetailedMissingLog = $true
    if ($EnableDetailedMissingLog -and $missingMedia.Count -gt 0) {
        $missingReportPath = Join-Path $localRoot "_missing-media.txt"
        if (Test-Path $missingReportPath) { Remove-Item $missingReportPath -Force }

        foreach ($sys in $missingMedia.Keys) {
            $reportLines = @()
            $reportLines += "[$sys]"
            foreach ($rom in $missingMedia[$sys].Keys) {
                $types = ($missingMedia[$sys][$rom] | Sort-Object) -join ", "
                $reportLines += "$rom ($types)"
            }
            $reportLines += ""
            $reportLines | Out-File -FilePath $missingReportPath -Append -Encoding UTF8
        }

        Write-Log "Some media is missing. See _missing-media.txt in the local directory."
    }
    elseif (-not $EnableDetailedMissingLog -and $missingMedia.Count -gt 0) {
        Write-Log "Some media is missing."
    }
    else {
        Write-Log "All media present!"
    }

    if ($ProgressBar) { $ProgressBar.Value = 100; Start-Sleep -Milliseconds 300; $ProgressBar.Value = 0 }
}

# ---------- Run ----------
$btn.Add_Click({
    $frontendUsing   = $cboFrontendUsing.SelectedItem.ToString()
    $frontendFrom    = $cboFrontendFrom.SelectedItem.ToString()
    $localRomPath    = $txtLocalRomPath.Text
    $remoteMediaPath = $txtRemoteMediaPath.Text
    $localMediaPath  = $txtLocalMediaPath.Text

    # Require Local Media Path when destination is EmuDeck/RetroDeck
    if ($frontendUsing -in @('EmuDeck','RetroDeck')) {
        if ([string]::IsNullOrWhiteSpace($localMediaPath)) {
            [System.Windows.Forms.MessageBox]::Show(
                "For $frontendUsing as the destination, please set 'Optional Local Media Path'. " +
                "Media will be written under <that>\downloaded_media\<system>\{screenshots|marquees|covers|videos}.",
                "Needs Local Media Path",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            return
        }
    }


    if ([string]::IsNullOrWhiteSpace($localRomPath) -or [string]::IsNullOrWhiteSpace($remoteMediaPath)) {
        [System.Windows.Forms.MessageBox]::Show("Local ROM Path and Remote Media Path are required.", "Missing Info",
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    $syncImages = $rbImages.Checked -or $rbBoth.Checked
    $syncVideos = $rbVideos.Checked -or $rbBoth.Checked

    try {
        Sync-Media -localRoot $localRomPath -remoteRoot $remoteMediaPath `
                   -FrontendUsing $frontendUsing -FrontendFrom $frontendFrom `
                   -SyncImages $syncImages -SyncVideos $syncVideos `
                   -ProgressBar $progress
        [System.Windows.Forms.MessageBox]::Show("Media processing complete.", "Done",
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error during sync: $_", "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

[void]$form.ShowDialog()
