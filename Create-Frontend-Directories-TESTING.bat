@echo off
setlocal EnableExtensions EnableDelayedExpansion
pushd "%~dp0"

:: ===== Root folders =====
set "ROOT=_rom-folder-test"
set "LOCAL=%ROOT%\Local"
set "REMOTE=%ROOT%\Remote"

:: Frontends
set "FRONTENDS=RetroBat Batocera EmuDeck RetroDeck LaunchBox RGS"

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
:: Create LOCAL structures (ROMs only)
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
        set "GBASE=%LOCAL%\%%F\Games\!SYS!"
        echo     MKDIR "!GBASE!"
        mkdir "!GBASE!" >nul 2>&1
        for /L %%I in (1,1,5) do (
          set "ROM=!GAME[%%I]!"
          echo Dummy ROM for !ROM!>"!GBASE!\!ROM!.zip"
        )
      ) else (
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
:: Create REMOTE structures (media trees)
:: ----------------------------
echo.
echo === Creating REMOTE structures (media trees) ===
for %%F in (%FRONTENDS%) do (
  if /i not "%%F"=="RGS" (
    echo   %%F
    call :RemoteProfile "%%F"
    set "RPROF=!OUT_REMOTE!"

    echo     MKDIR "%REMOTE%\%%F"
    mkdir "%REMOTE%\%%F" >nul 2>&1

    for %%C in (%CANON_LIST%) do (
      call :MapSystem "%%F" "%%C"
      set "SYS=!OUT_SYS!"
      if not defined SYS (
        echo     Skipping unknown system %%C for %%F
      ) else (
        if /i "!RPROF!"=="LB" (
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
            mkdir "%REMOTE%\%%F\Games\!SYS!" >nul 2>&1
            echo Remote ROM for !ROM!>"%REMOTE%\%%F\Games\!SYS!\!ROM!.zip"
            echo LB screenshot for !ROM!>"!IMBASE!\Screenshots\!ROM!.png"
            echo LB marquee for !ROM!>"!IMBASE!\Marquees\!ROM!.png"
            echo LB cover for !ROM!>"!IMBASE!\Covers\!ROM!.png"
            echo LB video for !ROM!>"!VIDBASE!\!ROM!.mp4"
          )

        ) else if /i "!RPROF!"=="EMU" (
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
            mkdir "%REMOTE%\%%F\roms\!SYS!" >nul 2>&1
            echo Remote ROM for !ROM!>"%REMOTE%\%%F\roms\!SYS!\!ROM!.zip"
            echo EMU screenshot for !ROM!>"!DMBASE!\screenshots\!ROM!.png"
            echo EMU marquee for !ROM!>"!DMBASE!\marquees\!ROM!.png"
            echo EMU cover for !ROM!>"!DMBASE!\covers\!ROM!.png"
            echo EMU video for !ROM!>"!DMBASE!\videos\!ROM!.mp4"
          )
        ) else (
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
)

:: =========================
:: RGS REMOTE STRUCTURE (fixed)
:: =========================
echo.
echo === Creating REMOTE structures (media trees) for RGS ===
setlocal EnableDelayedExpansion
set "FRONTEND=RGS"
set "FRONTEND_DIR=%REMOTE%\%FRONTEND%"
mkdir "%FRONTEND_DIR%" >nul 2>&1

for %%C in (nes snes megadrive gba n64) do (
  set "SYS=%%C"
  set "SYS_DIR=!FRONTEND_DIR!\!SYS!"
  set "MEDIA_DIR=!SYS_DIR!\media"
  echo   Creating !MEDIA_DIR! structure...
  mkdir "!MEDIA_DIR!\box2d"      >nul 2>&1
  mkdir "!MEDIA_DIR!\boxback"    >nul 2>&1
  mkdir "!MEDIA_DIR!\cartridges" >nul 2>&1
  mkdir "!MEDIA_DIR!\fanarts"    >nul 2>&1
  mkdir "!MEDIA_DIR!\images"     >nul 2>&1
  mkdir "!MEDIA_DIR!\manuals"    >nul 2>&1
  mkdir "!MEDIA_DIR!\maps"       >nul 2>&1
  mkdir "!MEDIA_DIR!\marquee"    >nul 2>&1
  mkdir "!MEDIA_DIR!\music"      >nul 2>&1
  mkdir "!MEDIA_DIR!\thumbnails" >nul 2>&1
  mkdir "!MEDIA_DIR!\titles"     >nul 2>&1
  mkdir "!MEDIA_DIR!\videos"     >nul 2>&1

  for /L %%I in (1,1,5) do (
    set "ROM=!GAME[%%I]!"
    echo Dummy RGS ROM for !ROM!>"!SYS_DIR!\!ROM!.zip"
    echo RGS box2d for !ROM!>"!MEDIA_DIR!\box2d\!ROM!.png"
    echo RGS screenshot for !ROM!>"!MEDIA_DIR!\images\!ROM!.png"
    echo RGS marquee for !ROM!>"!MEDIA_DIR!\marquee\!ROM!.png"
    echo RGS video for !ROM!>"!MEDIA_DIR!\videos\!ROM!.mp4"
    echo RGS thumbnail for !ROM!>"!MEDIA_DIR!\thumbnails\!ROM!.png"
    echo RGS title for !ROM!>"!MEDIA_DIR!\titles\!ROM!.png"
  )
)
endlocal

:: =========================
:: Subroutines (helpers)
:: =========================
:MapSystem
set "OUT_SYS="
set "F=%~1"
set "C=%~2"
if /i "%F%"=="RetroBat" (
  if /i "%C%"=="genesis" set "OUT_SYS=megadrive"
  if /i "%C%"=="gba"      set "OUT_SYS=gba"
  if /i "%C%"=="n64"      set "OUT_SYS=n64"
  if /i "%C%"=="snes"     set "OUT_SYS=snes"
  if /i "%C%"=="nes"      set "OUT_SYS=nes"
) else if /i "%F%"=="Batocera" (
  if /i "%C%"=="genesis" set "OUT_SYS=megadrive"
  if /i "%C%"=="gba"      set "OUT_SYS=gba"
  if /i "%C%"=="n64"      set "OUT_SYS=n64"
  if /i "%C%"=="snes"     set "OUT_SYS=snes"
  if /i "%C%"=="nes"      set "OUT_SYS=nes"
) else if /i "%F%"=="LaunchBox" (
  if /i "%C%"=="genesis" set "OUT_SYS=Sega Genesis"
  if /i "%C%"=="gba"      set "OUT_SYS=Nintendo Game Boy Advance"
  if /i "%C%"=="n64"      set "OUT_SYS=Nintendo 64"
  if /i "%C%"=="snes"     set "OUT_SYS=Super Nintendo Entertainment System"
  if /i "%C%"=="nes"      set "OUT_SYS=Nintendo Entertainment System"
) else if /i "%F%"=="RGS" (
  if /i "%C%"=="genesis" set "OUT_SYS=megadrive"
  if /i "%C%"=="gba"      set "OUT_SYS=gba"
  if /i "%C%"=="n64"      set "OUT_SYS=n64"
  if /i "%C%"=="snes"     set "OUT_SYS=snes"
  if /i "%C%"=="nes"      set "OUT_SYS=nes"
) else (
  set "OUT_SYS=%C%"
)
goto :eof

:IsCentralized
set "OUT_CENTRALIZED=0"
if /i "%~1"=="LaunchBox" set "OUT_CENTRALIZED=1"
goto :eof

:RemoteProfile
set "OUT_REMOTE=FLAT"
if /i "%~1"=="LaunchBox"  set "OUT_REMOTE=LB"
if /i "%~1"=="EmuDeck"    set "OUT_REMOTE=EMU"
if /i "%~1"=="RetroDeck"  set "OUT_REMOTE=EMU"
if /i "%~1"=="RGS"        set "OUT_REMOTE=RGS"
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
goto :eof
