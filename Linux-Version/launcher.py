import os
import subprocess

# Function to clear the console
def clear_console():
    os.system('cls' if os.name == 'nt' else 'clear')

# Function to display the menu
def display_menu():
    clear_console()
    print("\033[93m^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\033[0m")
    print("\033[93mSEMUlator Rom Tools\033[0m")
    print("\033[93m~ ~~~~ V0.96 ~~~~~ ~\033[0m")
    print("\033[93mby Deadtrickz\033[0m")
    print("\033[93m^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\033[0m")
    print("\033[92m1: Copy Remote Rom Videos to Local Folder - LOOSE\033[0m")
    print("\033[92m2: Copy Remote Rom Videos to Local Folder - STRICT\033[0m")
    print("\033[92m3: Diff Files to Files\033[0m")
    print("\033[92m4: Diff Folders to Files\033[0m")
    print("\033[92m5: ES Find ALL Missing Videos\033[0m")
    print("\033[92m6: Find Duplicate Names\033[0m")
    print("\033[92m7: Find Duplicate Sizes\033[0m")
    print("\033[92m8: Launchbox Rename Media to Filename - NO FOLDER LIMITATIONS\033[0m")
    print("\033[92m9: Launchbox Rename Media to Filename\033[0m")
    print("\033[92m10: LB Copy Remote Rom Videos to Local Folder - LOOSE\033[0m")
    print("\033[92m11: LB Rename Media to Filename - Flatten Child Folder Files\033[0m")
    print("\033[92m12: LB Rename Media to Filename\033[0m")
    print("\033[92m13: LB Verify or Create Rom Folders\033[0m")
    print("\033[92m14: Verify or Create Bios Images Videos Folders\033[0m")
    print("\033[92m15: Verify or Create EmulationStation Folders\033[0m")
    print("\033[92m16: Zip Files to Zip\033[0m")
    print("\033[92m17: Zip Folders to Zip\033[0m")
    print("\033[92m18: Diff FILES - NORMALIZE NAMES\033[0m")
    print("\033[91mPress 'Q' to Quit\033[0m")

# Function to run the selected script
def run_script(script_name):
    subprocess.run(["python", script_name])

# Mapping of choices to script names
script_map = {
    "1": "scripts/Copy_Remote_Rom_Videos_to_Local_Folder-LOOSE.py",
    "2": "scripts/Copy_Remote_Rom_Videos_to_Local_Folder-STRICT.py",
    "3": "scripts/Diff-Files2Files.py",
    "4": "scripts/Diff-Folders2Files.py",
    "5": "scripts/ES_Find_ALL-MissingVideos.py",
    "6": "scripts/Find_DuplicateNames.py",
    "7": "scripts/Find_DuplicateSizes.py",
    "8": "scripts/Launchbox-RenameMedia2Filename-NO-FOLDER-LIMITATIONS.py",
    "9": "scripts/Launchbox-RenameMedia2Filename.py",
    "10": "scripts/LB-Copy_Remote_Rom_Videos_to_Local_Folder-LOOSE.py",
    "11": "scripts/LB-Rename_Media2Filename-FlattenChildFolderFiles.py",
    "12": "scripts/LB-Rename_Media2Filename.py",
    "13": "scripts/LB-Verify_or_Create_Rom_Folders.py",
    "14": "scripts/Verify_or_Create_BiosImagesVideos_Folders.py",
    "15": "scripts/Verify_or_Create_EmulationStation_Folders.py",
    "16": "scripts/Zip_Files2Zip.py",
    "17": "scripts/Zip_Folders2Zip.py",
    "18": "scripts/Diff-Files2Files-Normalized.py"
}

# Main loop
while True:
    display_menu()
    choice = input("Enter your choice: ").strip().upper()

    if choice == "Q":
        break

    if choice in script_map:
        run_script(script_map[choice])
    else:
        print("Invalid choice, please try again.")
        input("Press Enter to continue...")
