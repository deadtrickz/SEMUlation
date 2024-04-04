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

##### Option 1: Verify And Create Rom Folders In R:\roms
- verifies the R:\ network share exists and has the correct folders
- based on the EmulationStation folders
- if the folders are present, it will confirm it for you
- if they are not there it will over to create them for you.
## Credits
- dragoonDorise
	- emudeck made this possible. I've used much of dragoonDorise scripts/github to make this work.
- patorjk for the ASCII art
