@echo off
setlocal EnableDelayedExpansion

:: Enabling Virtual Terminal Sequence (ANSI escape codes) for color support
For /F %%G In ('Echo Prompt $E ^| "%__AppDir__%cmd.exe"') Do Set "ESC=%%G"

cls

:: Displaying header in yellow
echo %ESC%[93m^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%ESC%[0m
echo %ESC%[93mSEMUlator Rom Tools%ESC%[0m
echo %ESC%[93m~ ~~~~ V0.99 ~~~~~ ~%ESC%[0m
echo %ESC%[93mby Deadtrickz%ESC%[0m
echo %ESC%[93m^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%ESC%[0m

:: Display menu options in green
echo %ESC%[92m1: Find Missing Videos%ESC%[0m
echo %ESC%[92m2: Remote Media Copy - Slower - For Local HDD%ESC%[0m
echo %ESC%[92m3: Remote Media Copy - Faster - For Neworks%ESC%[0m
echo %ESC%[92m34: Match Media To Rom Names, Copy To Destination Folder - STRICT%ESC%[0m
echo %ESC%[92m4: Find Duplicate Named Files, Uses Filename Normalization%ESC%[0m
echo %ESC%[92m5: Find Files With Same File Sizes%ESC%[0m
echo %ESC%[92m6: Diff Files In Two Folders - LOOSE%ESC%[0m
echo %ESC%[92m7: Diff Files In Two Folders - STRICT%ESC%[0m
echo %ESC%[92m8: Diff Folders ONLY In Two Folders%ESC%[0m
echo %ESC%[92m9: Diff Folders To Files In Two Folders%ESC%[0m
echo %ESC%[92m20: Retrobat - Match IMAGES To Rom Names, Copy To Destination Folder - LOOSE%ESC%[0m
echo %ESC%[92m21: Retrobat - Match IMAGES To Rom Names, Copy To Destination Folder - STRICT%ESC%[0m
echo %ESC%[92m22: Retrobat - Match VIDEOS To Rom Names, Copy To Destination Folder - LOOSE%ESC%[0m
echo %ESC%[92m23: Retrobat - Match VIDEOS To Rom Names, Copy To Destination Folder - STRICT%ESC%[0m
echo %ESC%[92m24: Retrobat - Match MEDIA To Rom Names, Copy To Destination Folder - LOOSE%ESC%[0m
echo %ESC%[92m25: Retrobat - Match MEDIA To Rom Names, Copy To Destination Folder - STRICT%ESC%[0m
echo %ESC%[92m30: Zip All FILES In A Directory%ESC%[0m
echo %ESC%[92m31: Zip All FOLDERS In A Directory%ESC%[0m

echo %ESC%[91mPress "Q" to Quit%ESC%[0m

:: Input loop for user choice
:input
set /p choice=Enter your choice: 
if /i "!choice!"=="Q" goto :EOF

:: Handle choices
if "%choice%"=="1" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\01_Find_Missing_Videos.ps1"
if "%choice%"=="2" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\02_Remote_Media_Copy (slow_hdd).ps1"
if "%choice%"=="3" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\03_Remote_Media_Copy (fast_network).ps1"
if "%choice%"=="34" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\03_Generic_Match_Media_With_Rom_Name-STRICT.ps1"
if "%choice%"=="4" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\04_Find_DuplicateNames.ps1"
if "%choice%"=="5" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\05_Find_DuplicateSizes.ps1"
if "%choice%"=="6" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\06_Diff-Files2Files_LOOSE.ps1"
if "%choice%"=="7" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\07_Diff-Files2Files_STRICT.ps1"
if "%choice%"=="8" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\08_diff-folders-only.ps1"
if "%choice%"=="9" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\09_Diff-Folders2Files.ps1"
if "%choice%"=="20" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\20_Retrobat-Copy_Remote_Rom_IMAGES_to_Local_Folders-LOOSE.ps1"
if "%choice%"=="21" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\21_Retrobat-Copy_Remote_Rom_IMAGES_to_Local_Folders-STRICT.ps1"
if "%choice%"=="22" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\22_Retrobat-Copy_Remote_Rom_Videos_to_Local_Folders-LOOSE.ps1"
if "%choice%"=="23" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\23_Retrobat-Copy_Remote_Rom_Videos_to_Local_Folders-STRICT.ps1"
if "%choice%"=="24" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\24_Retrobat-Copy_Remote_Rom_MEDIA_to_Local_Folders-LOOSE.ps1"
if "%choice%"=="25" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\25_Retrobat-Copy_Remote_Rom_MEDIA_to_Local_Folders-STRICT.ps1"
if "%choice%"=="30" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\30_Zip_Files2Zip.ps1"
if "%choice%"=="31" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\31_Zip_Folders2Zip.ps1"

goto input