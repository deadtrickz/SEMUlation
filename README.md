# SEMUlation
SMB Emulation Tools


## Requirements
- Windows
- [Link Shell Extension](https://schinagl.priv.at/nt/hardlinkshellext/linkshellextension.html)
    - If you need to make symbolic links
- LaunchBox or EmulationStation Desktop Edition
	- Refer to LaunchBox or Emulation Station (emudeck)
- An "R" network share with the following child folders
	- bios
	- roms
	- images
	- videos
- The roms folder should have the emulationstation folder structure. This can be created with SEMUlator.ps1

## Usage
From cmd
```cmd
powershell.exe -executionpolicy unrestricted ".\SEMUlator.ps1"
```

##### Option 1: Verify or Create Rom Folders In R:\roms
- verifies the R:\ network share exists and has the correct folders
- based on the EmulationStation folders
- if the folders are present, it will confirm it for you
- if they are not there it will over to copy them from the "\_dev" directory

##### Option 2: Check/Create 'bios', 'images', and 'videos' folders in R:\
- verify the "bios", "images", "videos" folders exist in R:\
- if they are not found it will offer to create them

##### Option 3: Copy Rom Videos From Remote Folder To Local Folder - STRICT
- Takes user input for 3 file locations
	- 1: The ROM folder
	- 2: The remote video folder
	- 3: The local video folder
- 1: Checks the list of files in the rom folder
- 2: Compares that to the remote video folder
	- filenames must match, extensions are ignored
- 3: Copies the matched files to the local rom folder

##### Option 4: Copy Rom Videos From Remote Folder To Local Folder - IGNORE DESIGNATIONS - READS FOLDER NAMES ALSO
- Functionally the same as option 3
- ignores text inside () [] to match otherwise same filenames
- can read folder names as filenames to match folder based games

##### Option 5: Run A Diff On 2 folders
- Takes user input in 2 folder locations and compares them to find missing files
- Does NOT look at file extensions
- This is useful when trying to see what media is missing by comparing ROMs to your platforms video folder
	- Requires the names to match, obviously

##### Option 6: Run A Diff On 2 Folders - Use Folders as filenames
- Functionally the same as option 5
- Reads folder names as filenames to match folder based games

##### Option 98: Find Duplicate Filenames In A Folder
- searches filenames to find duplicate or similar files
- ignores text inside () [] to match otherwise same filenames

##### 99: Find Duplicate File Sizes In A Folder
- not really useful, was attempting to identify duplicates based on file size in a single directory.


---
---
## Credits
- dragoonDorise
	- emudeck made this possible. I've used much of dragoonDorise scripts/github to make this work.
- patorjk for the ASCII art
