@echo off
setlocal EnableDelayedExpansion

:: Enabling Virtual Terminal Sequence (ANSI escape codes) for color support
For /F %%G In ('Echo Prompt $E ^| "%__AppDir__%cmd.exe"') Do Set "ESC=%%G"

cls

:: Displaying header in yellow
echo %ESC%[93m^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%ESC%[0m
echo %ESC%[93mSEMUlator Rom Tools%ESC%[0m
echo %ESC%[93m~ ~~~~ V0.96 ~~~~~ ~%ESC%[0m
echo %ESC%[93mby Deadtrickz%ESC%[0m
echo %ESC%[93m^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%ESC%[0m

:: Display menu options in green
echo %ESC%[92m1: Copy Remote Rom Videos to Local Folder - LOOSE%ESC%[0m
echo %ESC%[92m2: Copy Remote Rom Videos to Local Folder - STRICT%ESC%[0m
echo %ESC%[92m3: Diff Files to Files%ESC%[0m
echo %ESC%[92m4: Diff Folders to Files%ESC%[0m
echo %ESC%[92m5: ES Find ALL Missing Videos%ESC%[0m
echo %ESC%[92m6: Find Duplicate Names%ESC%[0m
echo %ESC%[92m7: Find Duplicate Sizes%ESC%[0m
echo %ESC%[92m8: Launchbox Rename Media to Filename - NO FOLDER LIMITATIONS%ESC%[0m
echo %ESC%[92m9: Launchbox Rename Media to Filename%ESC%[0m
echo %ESC%[92m10: LB Copy Remote Rom Videos to Local Folder - LOOSE%ESC%[0m
echo %ESC%[92m11: LB Rename Media to Filename - Flatten Child Folder Files%ESC%[0m
echo %ESC%[92m12: LB Rename Media to Filename%ESC%[0m
echo %ESC%[92m13: LB Verify or Create Rom Folders%ESC%[0m
echo %ESC%[92m14: Verify or Create Bios Images Videos Folders%ESC%[0m
echo %ESC%[92m15: Verify or Create EmulationStation Folders%ESC%[0m
echo %ESC%[92m16: Zip Files to Zip%ESC%[0m
echo %ESC%[92m17: Zip Folders to Zip%ESC%[0m
echo %ESC%[92m18: Diff FILES - NORMALIZE NAMES%ESC%[0m

echo %ESC%[91mPress "Q" to Quit%ESC%[0m

:: Input loop for user choice
:input
set /p choice=Enter your choice: 
if /i "!choice!"=="Q" goto :EOF

:: Handle choices
if "%choice%"=="1" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\Copy_Remote_Rom_Videos_to_Local_Folder-LOOSE.ps1"
if "%choice%"=="2" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\Copy_Remote_Rom_Videos_to_Local_Folder-STRICT.ps1"
if "%choice%"=="3" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\Diff-Files2Files.ps1"
if "%choice%"=="4" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\Diff-Folders2Files.ps1"
if "%choice%"=="5" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\ES_Find_ALL-MissingVideos.ps1"
if "%choice%"=="6" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\Find_DuplicateNames.ps1"
if "%choice%"=="7" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\Find_DuplicateSizes.ps1"
if "%choice%"=="8" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\Launchbox-RenameMedia2Filename-NO-FOLDER-LIMITATIONS.ps1"
if "%choice%"=="9" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\Launchbox-RenameMedia2Filename.ps1"
if "%choice%"=="10" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\LB-Copy_Remote_Rom_Videos_to_Local_Folder-LOOSE.ps1"
if "%choice%"=="11" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\LB-Rename_Media2Filename-FlattenChildFolderFiles.ps1"
if "%choice%"=="12" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\LB-Rename_Media2Filename.ps1"
if "%choice%"=="13" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\LB-Verify_or_Create_Rom_Folders.ps1"
if "%choice%"=="14" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\Verify_or_Create_BiosImagesVideos_Folders.ps1"
if "%choice%"=="15" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\Verify_or_Create_EmulationStation_Folders.ps1"
if "%choice%"=="16" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\Zip_Files2Zip.ps1"
if "%choice%"=="17" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\Zip_Folders2Zip.ps1"
if "%choice%"=="18" wt -w 0 nt -d %CD% powershell.exe -executionpolicy unrestricted ".\scripts\Diff-Files2Files-Normalized.ps1"

goto input
