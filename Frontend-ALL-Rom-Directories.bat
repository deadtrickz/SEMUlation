@echo off
setlocal EnableExtensions EnableDelayedExpansion
pushd "%~dp0"

:: ===== Root folders =====
set "ROOT=_rom-folder-test"
set "LOCAL=%ROOT%\Local"
set "REMOTE=%ROOT%\Remote"

:: Frontends
set "FRONTENDS=RetroBat Batocera EmuDeck RetroDeck LaunchBox"

:: Canonical systems (extend as needed)
set "CANON_LIST=nes snes genesis gba n64"

:: Sample ROM names (messy on purpose)
set "GAME[1]=Card Balls (U) [P]"
set "GAME[2]=Turtleneck (U)"
set "GAME[3]=Jackhammer - The Game (E)"
set "GAME[4]=Bad Day Ted (J) [P][T]"
set "GAME[5]=The Lord of Arder - Rest v3.0 (J) [H] [T]"

echo Rebuilding "%ROOT%" sandbox...
if exist "%ROOT%" rmdir /s /q "%ROOT%"
mkdir "%LOCAL%" >nul 2>&1
mkdir "%REMOTE%" >nul 2>&1

:: ----------------------------
:: Create LOCAL structures (ROMs only) for all frontends
:: NOTE: No media folders for LaunchBox (or any) until the sync runs.
:: ----------------------------
echo.
echo === Creating LOCAL structures (ROMs only) ===
for %%F in (%FRONTENDS%) do (
  echo   %%F
  call :IsCentralized "%%F"
  set "CENT=!OUT_CENTRALIZED!"

  for %%C in (%CANON_LIST%) do (
    call :MapSystem "%%F" "%%C"
    set "SYS=!OUT_SYS!"
    if not defined SYS (
      echo     Skipping unknown system %%C for %%F
    ) else (
      if "!CENT!"=="1" (
        :: LaunchBox-style LOCAL: Games\<Platform>\ROMs ONLY
        set "GBASE=%LOCAL%\%%F\Games\!SYS!"
        echo     MKDIR "!GBASE!"
        mkdir "!GBASE!" >nul 2>&1
        for /L %%I in (1,1,5) do (
          set "ROM=!GAME[%%I]!"
          echo Dummy ROM for !ROM!>"!GBASE!\!ROM!.zip"
        )
      ) else (
        :: Flat-style LOCAL: <Frontend>\<system>\ROMs
        set "LDIR=%LOCAL%\%%F\!SYS!"
        echo     MKDIR "!LDIR!"
        mkdir "!LDIR!" >nul 2>&1
        for /L %%I in (1,1,5) do (
          set "ROM=!GAME[%%I]!"
          echo Dummy ROM for !ROM!>"!LDIR!\!ROM!.zip"
        )
      )
    )
  )
)

:: ----------------------------
:: Create REMOTE structures (media + optional ROMs) per-frontend
:: LaunchBox  -> centralized Images/Videos (plain filenames)
:: EmuDeck    -> downloaded_media\<system>\screenshots|marquees|covers|videos (plain filenames)
:: RetroDeck  -> same as EmuDeck
:: RetroBat/Batocera -> flat <system>\images|videos with suffixes
:: ----------------------------
echo.
echo === Creating REMOTE structures (media trees) ===
for %%F in (%FRONTENDS%) do (
  echo   %%F
  call :RemoteProfile "%%F"
  set "RPROF=!OUT_REMOTE!"

  :: ensure a frontend bucket exists
  echo     MKDIR "%REMOTE%\%%F"
  mkdir "%REMOTE%\%%F" >nul 2>&1

  for %%C in (%CANON_LIST%) do (
    call :MapSystem "%%F" "%%C"
    set "SYS=!OUT_SYS!"
    if not defined SYS (
      echo     Skipping unknown system %%C for %%F
    ) else (
      if /i "!RPROF!"=="LB" (
        :: LaunchBox centralized layout
        set "IMBASE=%REMOTE%\%%F\Images\!SYS!"
        set "VIDBASE=%REMOTE%\%%F\Videos\!SYS!"
        echo     MKDIR "!IMBASE!\Screenshots"
        echo     MKDIR "!IMBASE!\Marquees"
        echo     MKDIR "!IMBASE!\Covers"
        echo     MKDIR "!VIDBASE!"
        mkdir "!IMBASE!\Screenshots" >nul 2>&1
        mkdir "!IMBASE!\Marquees"   >nul 2>&1
        mkdir "!IMBASE!\Covers"     >nul 2>&1
        mkdir "!VIDBASE!"           >nul 2>&1

        for /L %%I in (1,1,5) do (
          set "ROM=!GAME[%%I]!"
          :: optional remote ROM dump
          mkdir "%REMOTE%\%%F\Games\!SYS!" >nul 2>&1
          echo Remote ROM for !ROM!>"%REMOTE%\%%F\Games\!SYS!\!ROM!.zip"

          echo LB screenshot for !ROM!>"!IMBASE!\Screenshots\!ROM!.png"
          echo LB marquee for !ROM!>"!IMBASE!\Marquees\!ROM!.png"
          echo LB cover for !ROM!>"!IMBASE!\Covers\!ROM!.png"
          echo LB video for !ROM!>"!VIDBASE!\!ROM!.mp4"
        )

      ) else if /i "!RPROF!"=="EMU" (
        :: EmuDeck/RetroDeck downloaded_media layout (plain filenames)
        set "DMBASE=%REMOTE%\%%F\downloaded_media\!SYS!"
        echo     MKDIR "!DMBASE!\screenshots"
        echo     MKDIR "!DMBASE!\marquees"
        echo     MKDIR "!DMBASE!\covers"
        echo     MKDIR "!DMBASE!\videos"
        mkdir "!DMBASE!\screenshots" >nul 2>&1
        mkdir "!DMBASE!\marquees"    >nul 2>&1
        mkdir "!DMBASE!\covers"      >nul 2>&1
        mkdir "!DMBASE!\videos"      >nul 2>&1

        for /L %%I in (1,1,5) do (
          set "ROM=!GAME[%%I]!"
          :: optional remote ROM dump
          mkdir "%REMOTE%\%%F\roms\!SYS!" >nul 2>&1
          echo Remote ROM for !ROM!>"%REMOTE%\%%F\roms\!SYS!\!ROM!.zip"

          echo EMU screenshot for !ROM!>"!DMBASE!\screenshots\!ROM!.png"
          echo EMU marquee for !ROM!>"!DMBASE!\marquees\!ROM!.png"
          echo EMU cover for !ROM!>"!DMBASE!\covers\!ROM!.png"
          echo EMU video for !ROM!>"!DMBASE!\videos\!ROM!.mp4"
        )

      ) else (
        :: Flat RetroBat/Batocera layout with suffixes
        set "RDIR=%REMOTE%\%%F\!SYS!"
        echo     MKDIR "!RDIR!\images"
        echo     MKDIR "!RDIR!\videos"
        mkdir "!RDIR!\images" >nul 2>&1
        mkdir "!RDIR!\videos" >nul 2>&1

        for /L %%I in (1,1,5) do (
          set "ROM=!GAME[%%I]!"
          echo Remote ROM for !ROM!>"!RDIR!\!ROM!.zip"
          echo Remote image for !ROM!>"!RDIR!\images\!ROM!-image.png"
          echo Remote marquee for !ROM!>"!RDIR!\images\!ROM!-marquee.png"
          echo Remote thumb for !ROM!>"!RDIR!\images\!ROM!-thumb.png"
          echo Remote video for !ROM!>"!RDIR!\videos\!ROM!-video.mp4"
        )
      )
    )
  )
)

call :PrintHelp
popd
exit /b 0

:: =========================
:: Subroutines (helpers)
:: =========================
:MapSystem
:: %1 = FRONTEND, %2 = CANON  -> sets OUT_SYS
set "OUT_SYS="
set "F=%~1"
set "C=%~2"

if /i "%F%"=="RetroBat" (
  if /i "%C%"=="nes"      set "OUT_SYS=nes"
  if /i "%C%"=="snes"     set "OUT_SYS=snes"
  if /i "%C%"=="genesis"  set "OUT_SYS=megadrive"
  if /i "%C%"=="gba"      set "OUT_SYS=gba"
  if /i "%C%"=="n64"      set "OUT_SYS=n64"

) else if /i "%F%"=="Batocera" (
  if /i "%C%"=="nes"      set "OUT_SYS=nes"
  if /i "%C%"=="snes"     set "OUT_SYS=snes"
  if /i "%C%"=="genesis"  set "OUT_SYS=megadrive"
  if /i "%C%"=="gba"      set "OUT_SYS=gba"
  if /i "%C%"=="n64"      set "OUT_SYS=n64"

) else if /i "%F%"=="EmuDeck" (
  if /i "%C%"=="nes"      set "OUT_SYS=nes"
  if /i "%C%"=="snes"     set "OUT_SYS=snes"
  if /i "%C%"=="genesis"  set "OUT_SYS=genesis"
  if /i "%C%"=="gba"      set "OUT_SYS=gba"
  if /i "%C%"=="n64"      set "OUT_SYS=n64"

) else if /i "%F%"=="RetroDeck" (
  if /i "%C%"=="nes"      set "OUT_SYS=nes"
  if /i "%C%"=="snes"     set "OUT_SYS=snes"
  if /i "%C%"=="genesis"  set "OUT_SYS=genesis"
  if /i "%C%"=="gba"      set "OUT_SYS=gba"
  if /i "%C%"=="n64"      set "OUT_SYS=n64"

) else if /i "%F%"=="LaunchBox" (
  if /i "%C%"=="nes"      set "OUT_SYS=Nintendo Entertainment System"
  if /i "%C%"=="snes"     set "OUT_SYS=Super Nintendo Entertainment System"
  if /i "%C%"=="genesis"  set "OUT_SYS=Sega Genesis"
  if /i "%C%"=="gba"      set "OUT_SYS=Nintendo Game Boy Advance"
  if /i "%C%"=="n64"      set "OUT_SYS=Nintendo 64"
)
goto :eof

:IsCentralized
:: sets OUT_CENTRALIZED (1 for LaunchBox local ROM organization)
set "OUT_CENTRALIZED=0"
if /i "%~1"=="LaunchBox" set "OUT_CENTRALIZED=1"
goto :eof

:RemoteProfile
:: Sets OUT_REMOTE = LB | EMU | FLAT (for REMOTE layout)
set "OUT_REMOTE=FLAT"
if /i "%~1"=="LaunchBox"  set "OUT_REMOTE=LB"
if /i "%~1"=="EmuDeck"    set "OUT_REMOTE=EMU"
if /i "%~1"=="RetroDeck"  set "OUT_REMOTE=EMU"
goto :eof

:PrintHelp
>CON echo.
>CON echo Done.
>CON echo Local root:  %LOCAL%
>CON echo Remote root: %REMOTE%
>CON echo.
>CON echo Use these paths in your GUI to test each pair:
>CON echo   Local ROM Path   = %LOCAL%\[Frontend]
>CON echo   Remote Media Path= %REMOTE%\[Frontend]
>CON echo.
>CON echo Examples:
>CON echo   Using: RetroBat   ^| From: LaunchBox   ^=^> Local: %LOCAL%\RetroBat   Remote: %REMOTE%\LaunchBox
>CON echo   Using: EmuDeck    ^| From: LaunchBox   ^=^> Local: %LOCAL%\EmuDeck    Remote: %REMOTE%\LaunchBox
>CON echo   Using: RetroBat   ^| From: EmuDeck     ^=^> Local: %LOCAL%\RetroBat   Remote: %REMOTE%\EmuDeck
>CON echo.
goto :eof
