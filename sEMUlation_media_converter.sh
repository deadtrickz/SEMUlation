#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Media Sync (Steam Deck/Linux) — interactive CLI version
# - Choose destination frontend (the one you're USING)
# - Choose source frontend (where the MEDIA is FROM)
# - Enter Local ROM Path, Remote Media Path, Optional Local Media Path
#   (3rd is REQUIRED for EmuDeck/RetroDeck, optional otherwise)
# - Copies images & videos matching your ROMs
# - Writes a _missing-media.txt report in the local ROM root
# ============================================================

# ------------- small utils -------------
err() { echo "ERROR: $*" >&2; exit 1; }
log() { printf '%s\n' "$*"; }
ensure_dir() { mkdir -p -- "$1"; }

clean_name() {
  local s="$1"
  s="${s//_/ }"
  s="$(sed -E 's/[[:space:]]+/ /g; s/\[[^]]*\]//g; s/\([^)]*\)//g' <<<"$s")"
  s="$(sed -E 's/[-_](0[1-9]|[1-9][0-9])$//' <<<"$s")"
  s="$(sed -E 's/\.ps3$//' <<<"$s")"
  s="$(sed -E 's/[^A-Za-z0-9 ]//g' <<<"$s")"
  s="$(sed -E 's/[[:space:]]+/ /g; s/^[[:space:]]+|[[:space:]]+$//g' <<<"$s")"
  printf '%s' "$s"
}

build_dest_filename() {
  local pattern="$1" rombase="$2" ext="$3" suffix="${4:-}"
  local out="${pattern//\{rom\}/$rombase}"
  out="${out//\{ext\}/$ext}"
  out="${out//\{suffix\}/$suffix}"
  printf '%s' "$out"
}

list_files_0() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    find "$dir" -maxdepth 1 -type f -print0 2>/dev/null || true
  fi
}

base_noext() {
  local p="$1"
  local b; b="$(basename -- "$p")"
  if [[ "$b" == *.ps3 ]]; then
    printf '%s' "$b"  # keep .ps3 whole (matches your PS script behavior)
  else
    printf '%s' "${b%.*}"
  fi
}

ext_withdot() {
  local p="$1"
  local b; b="$(basename -- "$p")"
  local e="${b##*.}"
  if [[ "$e" == "$b" || "$b" == *.ps3 ]]; then
    printf '%s' ""
  else
    printf '.%s' "$e"
  fi
}

find_match() {
  # $1 matchMode (Plain|Suffix)
  # $2 suffix token (may be empty for Plain)
  # $3 cleaned rom name
  # $4.. candidate files
  local mode="$1" suf="$2" cleanrom="$3"; shift 3
  local f base stem
  if [[ "$mode" == "Suffix" && -n "$suf" ]]; then
    for f in "$@"; do
      base="$(base_noext "$f")"
      if [[ "$base" =~ -${suf}$ ]]; then
        stem="${base%-${suf}}"
        if [[ "$(clean_name "$stem")" == "$cleanrom" ]]; then
          printf '%s' "$f"; return 0
        fi
      fi
    done
    # fallback to plain if not found
    for f in "$@"; do
      base="$(base_noext "$f")"
      if [[ "$(clean_name "$base")" == "$cleanrom" ]]; then
        printf '%s' "$f"; return 0
      fi
    done
  else
    for f in "$@"; do
      base="$(base_noext "$f")"
      if [[ "$(clean_name "$base")" == "$cleanrom" ]]; then
        printf '%s' "$f"; return 0
      fi
      if [[ -n "$suf" && "$base" =~ -${suf}$ ]]; then
        stem="${base%-${suf}}"
        if [[ "$(clean_name "$stem")" == "$cleanrom" ]]; then
          printf '%s' "$f"; return 0
        fi
      fi
    done
  fi
  return 1
}

# ------------- interactive prompts -------------
FRONTENDS=("Batocera" "EmuDeck" "LaunchBox" "RetroBat" "RetroDeck" "RGS")

choose_frontend() {
  local title="$1"
  echo ""
  echo "$title"
  local i
  for (( i=0; i<${#FRONTENDS[@]}; i++ )); do
    printf "  %d) %s\n" "$((i+1))" "${FRONTENDS[$i]}"
  done
  local sel=""
  while :; do
    read -rp "Enter choice [1-${#FRONTENDS[@]}]: " sel
    [[ "$sel" =~ ^[1-9][0-9]*$ ]] || { echo "Please enter a number."; continue; }
    (( sel>=1 && sel<=${#FRONTENDS[@]} )) || { echo "Out of range."; continue; }
    break
  done
  echo "${FRONTENDS[$((sel-1))]}"
}

prompt_paths() {
  local using="$1"
  echo ""
  read -erp "Local ROM Path (where your ROM folders are): " LOCAL_ROM_PATH
  [[ -d "$LOCAL_ROM_PATH" ]] || err "Local ROM Path does not exist: $LOCAL_ROM_PATH"

  read -erp "Remote Media Path (where media comes FROM): " REMOTE_MEDIA_PATH
  [[ -d "$REMOTE_MEDIA_PATH" ]] || err "Remote Media Path does not exist: $REMOTE_MEDIA_PATH"

  if [[ "$using" == "EmuDeck" || "$using" == "RetroDeck" ]]; then
    echo "(Required for $using) This is the base that contains downloaded_media/"
    read -erp "Local Media Path (destination base): " LOCAL_MEDIA_PATH
    [[ -d "$LOCAL_MEDIA_PATH" ]] || err "Local Media Path does not exist: $LOCAL_MEDIA_PATH"
  else
    read -erp "(Optional) Local Media Path (press Enter to skip): " LOCAL_MEDIA_PATH || true
    if [[ -n "${LOCAL_MEDIA_PATH:-}" && ! -d "$LOCAL_MEDIA_PATH" ]]; then
      err "Local Media Path was provided but does not exist: $LOCAL_MEDIA_PATH"
    fi
  fi
}

# ------------- canonical mapping (FULL) -------------
declare -A CANON
# (Key is "canonical|Frontend" -> system-name)
CANON["mame|RetroBat"]="mame";           CANON["mame|Batocera"]="mame";           CANON["mame|EmuDeck"]="mame";           CANON["mame|RetroDeck"]="mame";           CANON["mame|LaunchBox"]="Arcade"
CANON["n64|RetroBat"]="n64";             CANON["n64|Batocera"]="n64";             CANON["n64|EmuDeck"]="n64";             CANON["n64|RetroDeck"]="n64";             CANON["n64|LaunchBox"]="Nintendo 64"
CANON["nes|RetroBat"]="nes";             CANON["nes|Batocera"]="nes";             CANON["nes|EmuDeck"]="nes";             CANON["nes|RetroDeck"]="nes";             CANON["nes|LaunchBox"]="Nintendo Entertainment System"
CANON["ps2|RetroBat"]="ps2";             CANON["ps2|Batocera"]="ps2";             CANON["ps2|EmuDeck"]="ps2";             CANON["ps2|RetroDeck"]="ps2";             CANON["ps2|LaunchBox"]="Sony PlayStation 2"
CANON["psp|RetroBat"]="psp";             CANON["psp|Batocera"]="psp";             CANON["psp|EmuDeck"]="psp";             CANON["psp|RetroDeck"]="psp";             CANON["psp|LaunchBox"]="Sony PSP"
CANON["psx|RetroBat"]="psx";             CANON["psx|Batocera"]="psx";             CANON["psx|EmuDeck"]="psx";             CANON["psx|RetroDeck"]="psx";             CANON["psx|LaunchBox"]="Sony PlayStation"
CANON["gba|RetroBat"]="gba";             CANON["gba|Batocera"]="gba";             CANON["gba|EmuDeck"]="gba";             CANON["gba|RetroDeck"]="gba";             CANON["gba|LaunchBox"]="Nintendo Game Boy Advance"
CANON["gb|RetroBat"]="gb";               CANON["gb|Batocera"]="gb";               CANON["gb|EmuDeck"]="gb";               CANON["gb|RetroDeck"]="gb";               CANON["gb|LaunchBox"]="Nintendo Game Boy"
CANON["gbc|RetroBat"]="gbc";             CANON["gbc|Batocera"]="gbc";             CANON["gbc|EmuDeck"]="gbc";             CANON["gbc|RetroDeck"]="gbc";             CANON["gbc|LaunchBox"]="Nintendo Game Boy Color"
CANON["snes|RetroBat"]="snes";           CANON["snes|Batocera"]="snes";           CANON["snes|EmuDeck"]="snes";           CANON["snes|RetroDeck"]="snes";           CANON["snes|LaunchBox"]="Super Nintendo Entertainment System"
CANON["3do|RetroBat"]="3do";             CANON["3do|Batocera"]="3do";             CANON["3do|EmuDeck"]="3do";             CANON["3do|RetroDeck"]="3do";             CANON["3do|LaunchBox"]="3DO Interactive Multiplayer"
CANON["ags|RetroBat"]="ags";             CANON["ags|Batocera"]="ags";             CANON["ags|EmuDeck"]="ags";             CANON["ags|RetroDeck"]="ags";             CANON["ags|LaunchBox"]="Adventure Game Studio"
CANON["amiga|RetroBat"]="amiga";         CANON["amiga|Batocera"]="amiga";         CANON["amiga|EmuDeck"]="amiga";         CANON["amiga|RetroDeck"]="amiga";         CANON["amiga|LaunchBox"]="Commodore Amiga"
CANON["amiga1200|RetroBat"]="amiga1200"; CANON["amiga1200|Batocera"]="amiga1200"; CANON["amiga1200|EmuDeck"]="amiga1200"; CANON["amiga1200|RetroDeck"]="amiga1200"; CANON["amiga1200|LaunchBox"]="Commodore Amiga 1200"
CANON["amiga600|RetroBat"]="amiga600";   CANON["amiga600|Batocera"]="amiga600";   CANON["amiga600|EmuDeck"]="amiga600";   CANON["amiga600|RetroDeck"]="amiga600";   CANON["amiga600|LaunchBox"]="Commodore Amiga 600"
CANON["amigacd32|RetroBat"]="amigacd32"; CANON["amigacd32|Batocera"]="amigacd32"; CANON["amigacd32|EmuDeck"]="amigacd32"; CANON["amigacd32|RetroDeck"]="amigacd32"; CANON["amigacd32|LaunchBox"]="Commodore Amiga CD32"
CANON["amstradcpc|RetroBat"]="amstradcpc"; CANON["amstradcpc|Batocera"]="amstradcpc"; CANON["amstradcpc|EmuDeck"]="amstradcpc"; CANON["amstradcpc|RetroDeck"]="amstradcpc"; CANON["amstradcpc|LaunchBox"]="Amstrad CPC"
CANON["android|RetroBat"]="android";     CANON["android|Batocera"]="android";     CANON["android|EmuDeck"]="android";     CANON["android|RetroDeck"]="android";     CANON["android|LaunchBox"]="Android"
CANON["apple2|RetroBat"]="apple2";       CANON["apple2|Batocera"]="apple2";       CANON["apple2|EmuDeck"]="apple2";       CANON["apple2|RetroDeck"]="apple2";       CANON["apple2|LaunchBox"]="Apple II"
CANON["apple2gs|RetroBat"]="apple2gs";   CANON["apple2gs|Batocera"]="apple2gs";   CANON["apple2gs|EmuDeck"]="apple2gs";   CANON["apple2gs|RetroDeck"]="apple2gs";   CANON["apple2gs|LaunchBox"]="Apple IIGS"
CANON["arcade|RetroBat"]="arcade";       CANON["arcade|Batocera"]="arcade";       CANON["arcade|EmuDeck"]="arcade";       CANON["arcade|RetroDeck"]="arcade";       CANON["arcade|LaunchBox"]="Arcade"
CANON["arcadia|RetroBat"]="arcadia";     CANON["arcadia|Batocera"]="arcadia";     CANON["arcadia|EmuDeck"]="arcadia";     CANON["arcadia|RetroDeck"]="arcadia";     CANON["arcadia|LaunchBox"]="Arcadia 2001"
CANON["arduboy|RetroBat"]="arduboy";     CANON["arduboy|Batocera"]="arduboy";     CANON["arduboy|EmuDeck"]="arduboy";     CANON["arduboy|RetroDeck"]="arduboy";     CANON["arduboy|LaunchBox"]="Arduboy"
CANON["astrocde|RetroBat"]="astrocde";   CANON["astrocde|Batocera"]="astrocde";   CANON["astrocde|EmuDeck"]="astrocde";   CANON["astrocde|RetroDeck"]="astrocde";   CANON["astrocde|LaunchBox"]="Bally Astrocade"
CANON["atari2600|RetroBat"]="atari2600"; CANON["atari2600|Batocera"]="atari2600"; CANON["atari2600|EmuDeck"]="atari2600"; CANON["atari2600|RetroDeck"]="atari2600"; CANON["atari2600|LaunchBox"]="Atari 2600"
CANON["atari5200|RetroBat"]="atari5200"; CANON["atari5200|Batocera"]="atari5200"; CANON["atari5200|EmuDeck"]="atari5200"; CANON["atari5200|RetroDeck"]="atari5200"; CANON["atari5200|LaunchBox"]="Atari 5200"
CANON["atari7800|RetroBat"]="atari7800"; CANON["atari7800|Batocera"]="atari7800"; CANON["atari7800|EmuDeck"]="atari7800"; CANON["atari7800|RetroDeck"]="atari7800"; CANON["atari7800|LaunchBox"]="Atari 7800"
CANON["atari800|RetroBat"]="atari800";   CANON["atari800|Batocera"]="atari800";   CANON["atari800|EmuDeck"]="atari800";   CANON["atari800|RetroDeck"]="atari800";   CANON["atari800|LaunchBox"]="Atari 8-bit Family"
CANON["atarijaguar|RetroBat"]="atarijaguar"; CANON["atarijaguar|Batocera"]="atarijaguar"; CANON["atarijaguar|EmuDeck"]="atarijaguar"; CANON["atarijaguar|RetroDeck"]="atarijaguar"; CANON["atarijaguar|LaunchBox"]="Atari Jaguar"
CANON["atarijaguarcd|RetroBat"]="atarijaguarcd"; CANON["atarijaguarcd|Batocera"]="atarijaguarcd"; CANON["atarijaguarcd|EmuDeck"]="atarijaguarcd"; CANON["atarijaguarcd|RetroDeck"]="atarijaguarcd"; CANON["atarijaguarcd|LaunchBox"]="Atari Jaguar CD"
CANON["atarilynx|RetroBat"]="atarilynx"; CANON["atarilynx|Batocera"]="atarilynx"; CANON["atarilynx|EmuDeck"]="atarilynx"; CANON["atarilynx|RetroDeck"]="atarilynx"; CANON["atarilynx|LaunchBox"]="Atari Lynx"
CANON["atarist|RetroBat"]="atarist";     CANON["atarist|Batocera"]="atarist";     CANON["atarist|EmuDeck"]="atarist";     CANON["atarist|RetroDeck"]="atarist";     CANON["atarist|LaunchBox"]="Atari ST"
CANON["atarixe|RetroBat"]="atarixe";     CANON["atarixe|Batocera"]="atarixe";     CANON["atarixe|EmuDeck"]="atarixe";     CANON["atarixe|RetroDeck"]="atarixe";     CANON["atarixe|LaunchBox"]="Atari XE"
CANON["atomiswave|RetroBat"]="atomiswave"; CANON["atomiswave|Batocera"]="atomiswave"; CANON["atomiswave|EmuDeck"]="atomiswave"; CANON["atomiswave|RetroDeck"]="atomiswave"; CANON["atomiswave|LaunchBox"]="Atomiswave"
CANON["bbcmicro|RetroBat"]="bbcmicro";   CANON["bbcmicro|Batocera"]="bbcmicro";   CANON["bbcmicro|EmuDeck"]="bbcmicro";   CANON["bbcmicro|RetroDeck"]="bbcmicro";   CANON["bbcmicro|LaunchBox"]="BBC Micro"
CANON["c16|RetroBat"]="c16";             CANON["c16|Batocera"]="c16";             CANON["c16|EmuDeck"]="c16";             CANON["c16|RetroDeck"]="c16";             CANON["c16|LaunchBox"]="Commodore 16"
CANON["c64|RetroBat"]="c64";             CANON["c64|Batocera"]="c64";             CANON["c64|EmuDeck"]="c64";             CANON["c64|RetroDeck"]="c64";             CANON["c64|LaunchBox"]="Commodore 64"
CANON["cavestory|RetroBat"]="cavestory"; CANON["cavestory|Batocera"]="cavestory"; CANON["cavestory|EmuDeck"]="cavestory"; CANON["cavestory|RetroDeck"]="cavestory"; CANON["cavestory|LaunchBox"]="Cave Story"
CANON["cdimono1|RetroBat"]="cdimono1";   CANON["cdimono1|Batocera"]="cdimono1";   CANON["cdimono1|EmuDeck"]="cdimono1";   CANON["cdimono1|RetroDeck"]="cdimono1";   CANON["cdimono1|LaunchBox"]="Philips CD-i"
CANON["cdtv|RetroBat"]="cdtv";           CANON["cdtv|Batocera"]="cdtv";           CANON["cdtv|EmuDeck"]="cdtv";           CANON["cdtv|RetroDeck"]="cdtv";           CANON["cdtv|LaunchBox"]="Commodore CDTV"
CANON["chailove|RetroBat"]="chailove";   CANON["chailove|Batocera"]="chailove";   CANON["chailove|EmuDeck"]="chailove";   CANON["chailove|RetroDeck"]="chailove";   CANON["chailove|LaunchBox"]="ChaiLove"
CANON["channelf|RetroBat"]="channelf";   CANON["channelf|Batocera"]="channelf";   CANON["channelf|EmuDeck"]="channelf";   CANON["channelf|RetroDeck"]="channelf";   CANON["channelf|LaunchBox"]="Fairchild Channel F"
CANON["cloud|RetroBat"]="cloud";         CANON["cloud|Batocera"]="cloud";         CANON["cloud|EmuDeck"]="cloud";         CANON["cloud|RetroDeck"]="cloud";         CANON["cloud|LaunchBox"]="Cloud"
CANON["coco|RetroBat"]="coco";           CANON["coco|Batocera"]="coco";           CANON["coco|EmuDeck"]="coco";           CANON["coco|RetroDeck"]="coco";           CANON["coco|LaunchBox"]="Tandy Color Computer"
CANON["colecovision|RetroBat"]="colecovision"; CANON["colecovision|Batocera"]="colecovision"; CANON["colecovision|EmuDeck"]="colecovision"; CANON["colecovision|RetroDeck"]="colecovision"; CANON["colecovision|LaunchBox"]="ColecoVision"
CANON["cps|RetroBat"]="cps";             CANON["cps|Batocera"]="cps";             CANON["cps|EmuDeck"]="cps";             CANON["cps|RetroDeck"]="cps";             CANON["cps|LaunchBox"]="Capcom Play System"
CANON["cps1|RetroBat"]="cps1";           CANON["cps1|Batocera"]="cps1";           CANON["cps1|EmuDeck"]="cps1";           CANON["cps1|RetroDeck"]="cps1";           CANON["cps1|LaunchBox"]="Capcom CPS-1"
CANON["cps2|RetroBat"]="cps2";           CANON["cps2|Batocera"]="cps2";           CANON["cps2|EmuDeck"]="cps2";           CANON["cps2|RetroDeck"]="cps2";           CANON["cps2|LaunchBox"]="Capcom CPS-2"
CANON["cps3|RetroBat"]="cps3";           CANON["cps3|Batocera"]="cps3";           CANON["cps3|EmuDeck"]="cps3";           CANON["cps3|RetroDeck"]="cps3";           CANON["cps3|LaunchBox"]="Capcom CPS-3"
CANON["crvision|RetroBat"]="crvision";   CANON["crvision|Batocera"]="crvision";   CANON["crvision|EmuDeck"]="crvision";   CANON["crvision|RetroDeck"]="crvision";   CANON["crvision|LaunchBox"]="VTech CreatiVision"
CANON["daphne|RetroBat"]="daphne";       CANON["daphne|Batocera"]="daphne";       CANON["daphne|EmuDeck"]="daphne";       CANON["daphne|RetroDeck"]="daphne";       CANON["daphne|LaunchBox"]="Daphne (Laserdisc)"
CANON["desktop|RetroBat"]="desktop";     CANON["desktop|Batocera"]="desktop";     CANON["desktop|EmuDeck"]="desktop";     CANON["desktop|RetroDeck"]="desktop";     CANON["desktop|LaunchBox"]="Desktop"
CANON["doom|RetroBat"]="doom";           CANON["doom|Batocera"]="doom";           CANON["doom|EmuDeck"]="doom";           CANON["doom|RetroDeck"]="doom";           CANON["doom|LaunchBox"]="Doom Ports"
CANON["dos|RetroBat"]="dos";             CANON["dos|Batocera"]="dos";             CANON["dos|EmuDeck"]="dos";             CANON["dos|RetroDeck"]="dos";             CANON["dos|LaunchBox"]="MS-DOS"
CANON["dragon32|RetroBat"]="dragon32";   CANON["dragon32|Batocera"]="dragon32";   CANON["dragon32|EmuDeck"]="dragon32";   CANON["dragon32|RetroDeck"]="dragon32";   CANON["dragon32|LaunchBox"]="Dragon 32/64"
CANON["dreamcast|RetroBat"]="dreamcast"; CANON["dreamcast|Batocera"]="dreamcast"; CANON["dreamcast|EmuDeck"]="dreamcast"; CANON["dreamcast|RetroDeck"]="dreamcast"; CANON["dreamcast|LaunchBox"]="Sega Dreamcast"
CANON["easyrpg|RetroBat"]="easyrpg";     CANON["easyrpg|Batocera"]="easyrpg";     CANON["easyrpg|EmuDeck"]="easyrpg";     CANON["easyrpg|RetroDeck"]="easyrpg";     CANON["easyrpg|LaunchBox"]="EasyRPG"
CANON["epic|RetroBat"]="epic";           CANON["epic|Batocera"]="epic";           CANON["epic|EmuDeck"]="epic";           CANON["epic|RetroDeck"]="epic";           CANON["epic|LaunchBox"]="Epic Games"
CANON["famicom|RetroBat"]="famicom";     CANON["famicom|Batocera"]="famicom";     CANON["famicom|EmuDeck"]="famicom";     CANON["famicom|RetroDeck"]="famicom";     CANON["famicom|LaunchBox"]="Nintendo Famicom"
CANON["fba|RetroBat"]="fba";             CANON["fba|Batocera"]="fba";             CANON["fba|EmuDeck"]="fba";             CANON["fba|RetroDeck"]="fba";             CANON["fba|LaunchBox"]="Arcade"
CANON["fbneo|RetroBat"]="fbneo";         CANON["fbneo|Batocera"]="fbneo";         CANON["fbneo|EmuDeck"]="fbneo";         CANON["fbneo|RetroDeck"]="fbneo";         CANON["fbneo|LaunchBox"]="Arcade"
CANON["fds|RetroBat"]="fds";             CANON["fds|Batocera"]="fds";             CANON["fds|EmuDeck"]="fds";             CANON["fds|RetroDeck"]="fds";             CANON["fds|LaunchBox"]="Famicom Disk System"
CANON["flash|RetroBat"]="flash";         CANON["flash|Batocera"]="flash";         CANON["flash|EmuDeck"]="flash";         CANON["flash|RetroDeck"]="flash";         CANON["flash|LaunchBox"]="Adobe Flash"
CANON["fmtowns|RetroBat"]="fmtowns";     CANON["fmtowns|Batocera"]="fmtowns";     CANON["fmtowns|EmuDeck"]="fmtowns";     CANON["fmtowns|RetroDeck"]="fmtowns";     CANON["fmtowns|LaunchBox"]="Fujitsu FM Towns"
CANON["gameandwatch|RetroBat"]="gameandwatch"; CANON["gameandwatch|Batocera"]="gameandwatch"; CANON["gameandwatch|EmuDeck"]="gameandwatch"; CANON["gameandwatch|RetroDeck"]="gameandwatch"; CANON["gameandwatch|LaunchBox"]="Nintendo Game & Watch"
CANON["gamecom|RetroBat"]="gamecom";     CANON["gamecom|Batocera"]="gamecom";     CANON["gamecom|EmuDeck"]="gamecom";     CANON["gamecom|RetroDeck"]="gamecom";     CANON["gamecom|LaunchBox"]="Tiger Game.com"
CANON["gamecube|RetroBat"]="gamecube";   CANON["gamecube|Batocera"]="gamecube";   CANON["gamecube|EmuDeck"]="gamecube";   CANON["gamecube|RetroDeck"]="gamecube";   CANON["gamecube|LaunchBox"]="Nintendo GameCube"
CANON["gamegear|RetroBat"]="gamegear";   CANON["gamegear|Batocera"]="gamegear";   CANON["gamegear|EmuDeck"]="gamegear";   CANON["gamegear|RetroDeck"]="gamegear";   CANON["gamegear|LaunchBox"]="Sega Game Gear"
CANON["genesis|RetroBat"]="megadrive";   CANON["genesis|Batocera"]="megadrive";   CANON["genesis|EmuDeck"]="genesis";     CANON["genesis|RetroDeck"]="genesis";     CANON["genesis|LaunchBox"]="Sega Genesis"
CANON["gx4000|RetroBat"]="gx4000";       CANON["gx4000|Batocera"]="gx4000";       CANON["gx4000|EmuDeck"]="gx4000";       CANON["gx4000|RetroDeck"]="gx4000";       CANON["gx4000|LaunchBox"]="Amstrad GX4000"
CANON["intellivision|RetroBat"]="intellivision"; CANON["intellivision|Batocera"]="intellivision"; CANON["intellivision|EmuDeck"]="intellivision"; CANON["intellivision|RetroDeck"]="intellivision"; CANON["intellivision|LaunchBox"]="Mattel Intellivision"
CANON["j2me|RetroBat"]="j2me";           CANON["j2me|Batocera"]="j2me";           CANON["j2me|EmuDeck"]="j2me";           CANON["j2me|RetroDeck"]="j2me";           CANON["j2me|LaunchBox"]="Java 2 Micro Edition"
CANON["kodi|RetroBat"]="kodi";           CANON["kodi|Batocera"]="kodi";           CANON["kodi|EmuDeck"]="kodi";           CANON["kodi|RetroDeck"]="kodi";           CANON["kodi|LaunchBox"]="Kodi"
CANON["lcdgames|RetroBat"]="lcdgames";   CANON["lcdgames|Batocera"]="lcdgames";   CANON["lcdgames|EmuDeck"]="lcdgames";   CANON["lcdgames|RetroDeck"]="lcdgames";   CANON["lcdgames|LaunchBox"]="LCD Handhelds"
CANON["lutris|RetroBat"]="lutris";       CANON["lutris|Batocera"]="lutris";       CANON["lutris|EmuDeck"]="lutris";       CANON["lutris|RetroDeck"]="lutris";       CANON["lutris|LaunchBox"]="Lutris"
CANON["lutro|RetroBat"]="lutro";         CANON["lutro|Batocera"]="lutro";         CANON["lutro|EmuDeck"]="lutro";         CANON["lutro|RetroDeck"]="lutro";         CANON["lutro|LaunchBox"]="Lutro"
CANON["macintosh|RetroBat"]="macintosh"; CANON["macintosh|Batocera"]="macintosh"; CANON["macintosh|EmuDeck"]="macintosh"; CANON["macintosh|RetroDeck"]="macintosh"; CANON["macintosh|LaunchBox"]="Apple Macintosh"
CANON["mame-advmame|RetroBat"]="mame-advmame"; CANON["mame-advmame|Batocera"]="mame-advmame"; CANON["mame-advmame|EmuDeck"]="mame-advmame"; CANON["mame-advmame|RetroDeck"]="mame-advmame"; CANON["mame-advmame|LaunchBox"]="Arcade"
CANON["mame-mame4all|RetroBat"]="mame-mame4all"; CANON["mame-mame4all|Batocera"]="mame-mame4all"; CANON["mame-mame4all|EmuDeck"]="mame-mame4all"; CANON["mame-mame4all|RetroDeck"]="mame-mame4all"; CANON["mame-mame4all|LaunchBox"]="Arcade"
CANON["mastersystem|RetroBat"]="mastersystem"; CANON["mastersystem|Batocera"]="mastersystem"; CANON["mastersystem|EmuDeck"]="mastersystem"; CANON["mastersystem|RetroDeck"]="mastersystem"; CANON["mastersystem|LaunchBox"]="Sega Master System"
CANON["megacd|RetroBat"]="megacd";       CANON["megacd|Batocera"]="megacd";       CANON["megacd|EmuDeck"]="megacd";       CANON["megacd|RetroDeck"]="megacd";       CANON["megacd|LaunchBox"]="Sega Mega-CD"
CANON["megacdjp|RetroBat"]="megacdjp";   CANON["megacdjp|Batocera"]="megacdjp";   CANON["megacdjp|EmuDeck"]="megacdjp";   CANON["megacdjp|RetroDeck"]="megacdjp";   CANON["megacdjp|LaunchBox"]="Sega Mega-CD (Japan)"
CANON["megadrive|RetroBat"]="megadrive"; CANON["megadrive|Batocera"]="megadrive"; CANON["megadrive|EmuDeck"]="genesis";   CANON["megadrive|RetroDeck"]="genesis";   CANON["megadrive|LaunchBox"]="Sega Genesis"
CANON["megadrivejp|RetroBat"]="megadrivejp"; CANON["megadrivejp|Batocera"]="megadrivejp"; CANON["megadrivejp|EmuDeck"]="genesis"; CANON["megadrivejp|RetroDeck"]="genesis"; CANON["megadrivejp|LaunchBox"]="Sega Mega Drive (JP)"
CANON["megaduck|RetroBat"]="megaduck";   CANON["megaduck|Batocera"]="megaduck";   CANON["megaduck|EmuDeck"]="megaduck";   CANON["megaduck|RetroDeck"]="megaduck";   CANON["megaduck|LaunchBox"]="Watara Supervision (Mega Duck)"
CANON["mess|RetroBat"]="mess";           CANON["mess|Batocera"]="mess";           CANON["mess|EmuDeck"]="mess";           CANON["mess|RetroDeck"]="mess";           CANON["mess|LaunchBox"]="MAME (MESS)"
CANON["model2|RetroBat"]="model2";       CANON["model2|Batocera"]="model2";       CANON["model2|EmuDeck"]="model2";       CANON["model2|RetroDeck"]="model2";       CANON["model2|LaunchBox"]="Sega Model 2"
CANON["model3|RetroBat"]="model3";       CANON["model3|Batocera"]="model3";       CANON["model3|EmuDeck"]="model3";       CANON["model3|RetroDeck"]="model3";       CANON["model3|LaunchBox"]="Sega Model 3"
CANON["moonlight|RetroBat"]="moonlight"; CANON["moonlight|Batocera"]="moonlight"; CANON["moonlight|EmuDeck"]="moonlight"; CANON["moonlight|RetroDeck"]="moonlight"; CANON["moonlight|LaunchBox"]="Moonlight"
CANON["moto|RetroBat"]="moto";           CANON["moto|Batocera"]="moto";           CANON["moto|EmuDeck"]="moto";           CANON["moto|RetroDeck"]="moto";           CANON["moto|LaunchBox"]="Motorola 680x0"
CANON["msx|RetroBat"]="msx";             CANON["msx|Batocera"]="msx";             CANON["msx|EmuDeck"]="msx";             CANON["msx|RetroDeck"]="msx";             CANON["msx|LaunchBox"]="Microsoft MSX"
CANON["msx1|RetroBat"]="msx1";           CANON["msx1|Batocera"]="msx1";           CANON["msx1|EmuDeck"]="msx1";           CANON["msx1|RetroDeck"]="msx1";           CANON["msx1|LaunchBox"]="Microsoft MSX"
CANON["msx2|RetroBat"]="msx2";           CANON["msx2|Batocera"]="msx2";           CANON["msx2|EmuDeck"]="msx2";           CANON["msx2|RetroDeck"]="msx2";           CANON["msx2|LaunchBox"]="Microsoft MSX2"
CANON["msxturbor|RetroBat"]="msxturbor"; CANON["msxturbor|Batocera"]="msxturbor"; CANON["msxturbor|EmuDeck"]="msxturbor"; CANON["msxturbor|RetroDeck"]="msxturbor"; CANON["msxturbor|LaunchBox"]="MSX Turbo R"
CANON["mugen|RetroBat"]="mugen";         CANON["mugen|Batocera"]="mugen";         CANON["mugen|EmuDeck"]="mugen";         CANON["mugen|RetroDeck"]="mugen";         CANON["mugen|LaunchBox"]="M.U.G.E.N"
CANON["multivision|RetroBat"]="multivision"; CANON["multivision|Batocera"]="multivision"; CANON["multivision|EmuDeck"]="multivision"; CANON["multivision|RetroDeck"]="multivision"; CANON["multivision|LaunchBox"]="Othello Multivision"
CANON["n3ds|RetroBat"]="3ds";            CANON["n3ds|Batocera"]="n3ds";           CANON["n3ds|EmuDeck"]="n3ds";           CANON["n3ds|RetroDeck"]="n3ds";           CANON["n3ds|LaunchBox"]="Nintendo 3DS"
CANON["n64dd|RetroBat"]="n64dd";         CANON["n64dd|Batocera"]="n64dd";         CANON["n64dd|EmuDeck"]="n64dd";         CANON["n64dd|RetroDeck"]="n64dd";         CANON["n64dd|LaunchBox"]="Nintendo 64DD"
CANON["naomi|RetroBat"]="naomi";         CANON["naomi|Batocera"]="naomi";         CANON["naomi|EmuDeck"]="naomi";         CANON["naomi|RetroDeck"]="naomi";         CANON["naomi|LaunchBox"]="Sega NAOMI"
CANON["naomigd|RetroBat"]="naomigd";     CANON["naomigd|Batocera"]="naomigd";     CANON["naomigd|EmuDeck"]="naomigd";     CANON["naomigd|RetroDeck"]="naomigd";     CANON["naomigd|LaunchBox"]="Sega NAOMI GD-ROM"
CANON["nds|RetroBat"]="nds";             CANON["nds|Batocera"]="nds";             CANON["nds|EmuDeck"]="nds";             CANON["nds|RetroDeck"]="nds";             CANON["nds|LaunchBox"]="Nintendo DS"
CANON["neogeo|RetroBat"]="neogeo";       CANON["neogeo|Batocera"]="neogeo";       CANON["neogeo|EmuDeck"]="neogeo";       CANON["neogeo|RetroDeck"]="neogeo";       CANON["neogeo|LaunchBox"]="SNK Neo Geo"
CANON["neogeocd|RetroBat"]="neogeocd";   CANON["neogeocd|Batocera"]="neogeocd";   CANON["neogeocd|EmuDeck"]="neogeocd";   CANON["neogeocd|RetroDeck"]="neogeocd";   CANON["neogeocd|LaunchBox"]="Neo Geo CD"
CANON["neogeocdjp|RetroBat"]="neogeocdjp"; CANON["neogeocdjp|Batocera"]="neogeocdjp"; CANON["neogeocdjp|EmuDeck"]="neogeocdjp"; CANON["neogeocdjp|RetroDeck"]="neogeocdjp"; CANON["neogeocdjp|LaunchBox"]="Neo Geo CD (Japan)"
CANON["ngp|RetroBat"]="ngp";             CANON["ngp|Batocera"]="ngp";             CANON["ngp|EmuDeck"]="ngp";             CANON["ngp|RetroDeck"]="ngp";             CANON["ngp|LaunchBox"]="Neo Geo Pocket"
CANON["ngpc|RetroBat"]="ngpc";           CANON["ngpc|Batocera"]="ngpc";           CANON["ngpc|EmuDeck"]="ngpc";           CANON["ngpc|RetroDeck"]="ngpc";           CANON["ngpc|LaunchBox"]="Neo Geo Pocket Color"
CANON["odyssey2|RetroBat"]="odyssey2";   CANON["odyssey2|Batocera"]="odyssey2";   CANON["odyssey2|EmuDeck"]="odyssey2";   CANON["odyssey2|RetroDeck"]="odyssey2";   CANON["odyssey2|LaunchBox"]="Magnavox Odyssey²"
CANON["openbor|RetroBat"]="openbor";     CANON["openbor|Batocera"]="openbor";     CANON["openbor|EmuDeck"]="openbor";     CANON["openbor|RetroDeck"]="openbor";     CANON["openbor|LaunchBox"]="OpenBOR"
CANON["oric|RetroBat"]="oric";           CANON["oric|Batocera"]="oric";           CANON["oric|EmuDeck"]="oric";           CANON["oric|RetroDeck"]="oric";           CANON["oric|LaunchBox"]="Oric"
CANON["palm|RetroBat"]="palm";           CANON["palm|Batocera"]="palm";           CANON["palm|EmuDeck"]="palm";           CANON["palm|RetroDeck"]="palm";           CANON["palm|LaunchBox"]="Palm OS"
CANON["pc|RetroBat"]="pc";               CANON["pc|Batocera"]="pc";               CANON["pc|EmuDeck"]="pc";               CANON["pc|RetroDeck"]="pc";               CANON["pc|LaunchBox"]="Windows"
CANON["pc88|RetroBat"]="pc88";           CANON["pc88|Batocera"]="pc88";           CANON["pc88|EmuDeck"]="pc88";           CANON["pc88|RetroDeck"]="pc88";           CANON["pc88|LaunchBox"]="NEC PC-8801"
CANON["pc98|RetroBat"]="pc98";           CANON["pc98|Batocera"]="pc98";           CANON["pc98|EmuDeck"]="pc98";           CANON["pc98|RetroDeck"]="pc98";           CANON["pc98|LaunchBox"]="NEC PC-9801"
CANON["pcengine|RetroBat"]="pcengine";   CANON["pcengine|Batocera"]="pcengine";   CANON["pcengine|EmuDeck"]="pcengine";   CANON["pcengine|RetroDeck"]="pcengine";   CANON["pcengine|LaunchBox"]="NEC PC Engine"
CANON["pcenginecd|RetroBat"]="pcenginecd"; CANON["pcenginecd|Batocera"]="pcenginecd"; CANON["pcenginecd|EmuDeck"]="pcenginecd"; CANON["pcenginecd|RetroDeck"]="pcenginecd"; CANON["pcenginecd|LaunchBox"]="NEC PC Engine CD-ROM²"
CANON["pcfx|RetroBat"]="pcfx";           CANON["pcfx|Batocera"]="pcfx";           CANON["pcfx|EmuDeck"]="pcfx";           CANON["pcfx|RetroDeck"]="pcfx";           CANON["pcfx|LaunchBox"]="NEC PC-FX"
CANON["pico8|RetroBat"]="pico8";         CANON["pico8|Batocera"]="pico8";         CANON["pico8|EmuDeck"]="pico8";         CANON["pico8|RetroDeck"]="pico8";         CANON["pico8|LaunchBox"]="PICO-8"
CANON["pokemini|RetroBat"]="pokemini";   CANON["pokemini|Batocera"]="pokemini";   CANON["pokemini|EmuDeck"]="pokemini";   CANON["pokemini|RetroDeck"]="pokemini";   CANON["pokemini|LaunchBox"]="Pokemon Mini"
CANON["ports|RetroBat"]="ports";         CANON["ports|Batocera"]="ports";         CANON["ports|EmuDeck"]="ports";         CANON["ports|RetroDeck"]="ports";         CANON["ports|LaunchBox"]="Ports"
CANON["primehacks|RetroBat"]="primehacks"; CANON["primehacks|Batocera"]="primehacks"; CANON["primehacks|EmuDeck"]="primehacks"; CANON["primehacks|RetroDeck"]="primehacks"; CANON["primehacks|LaunchBox"]="PrimeHack"
CANON["ps3|RetroBat"]="ps3";             CANON["ps3|Batocera"]="ps3";             CANON["ps3|EmuDeck"]="ps3";             CANON["ps3|RetroDeck"]="ps3";             CANON["ps3|LaunchBox"]="Sony PlayStation 3"
CANON["ps4|RetroBat"]="ps4";             CANON["ps4|Batocera"]="ps4";             CANON["ps4|EmuDeck"]="ps4";             CANON["ps4|RetroDeck"]="ps4";             CANON["ps4|LaunchBox"]="Sony PlayStation 4"
CANON["psvita|RetroBat"]="psvita";       CANON["psvita|Batocera"]="psvita";       CANON["psvita|EmuDeck"]="psvita";       CANON["psvita|RetroDeck"]="psvita";       CANON["psvita|LaunchBox"]="Sony PlayStation Vita"
CANON["pv1000|RetroBat"]="pv1000";       CANON["pv1000|Batocera"]="pv1000";       CANON["pv1000|EmuDeck"]="pv1000";       CANON["pv1000|RetroDeck"]="pv1000";       CANON["pv1000|LaunchBox"]="Casio PV-1000"
CANON["quake|RetroBat"]="quake";         CANON["quake|Batocera"]="quake";         CANON["quake|EmuDeck"]="quake";         CANON["quake|RetroDeck"]="quake";         CANON["quake|LaunchBox"]="Quake"
CANON["remoteplay|RetroBat"]="remoteplay"; CANON["remoteplay|Batocera"]="remoteplay"; CANON["remoteplay|EmuDeck"]="remoteplay"; CANON["remoteplay|RetroDeck"]="remoteplay"; CANON["remoteplay|LaunchBox"]="Remote Play"
CANON["samcoupe|RetroBat"]="samcoupe";   CANON["samcoupe|Batocera"]="samcoupe";   CANON["samcoupe|EmuDeck"]="samcoupe";   CANON["samcoupe|RetroDeck"]="samcoupe";   CANON["samcoupe|LaunchBox"]="SAM Coupé"
CANON["saturn|RetroBat"]="saturn";       CANON["saturn|Batocera"]="saturn";       CANON["saturn|EmuDeck"]="saturn";       CANON["saturn|RetroDeck"]="saturn";       CANON["saturn|LaunchBox"]="Sega Saturn"
CANON["saturnjp|RetroBat"]="saturnjp";   CANON["saturnjp|Batocera"]="saturnjp";   CANON["saturnjp|EmuDeck"]="saturnjp";   CANON["saturnjp|RetroDeck"]="saturnjp";   CANON["saturnjp|LaunchBox"]="Sega Saturn (Japan)"
CANON["scummvm|RetroBat"]="scummvm";     CANON["scummvm|Batocera"]="scummvm";     CANON["scummvm|EmuDeck"]="scummvm";     CANON["scummvm|RetroDeck"]="scummvm";     CANON["scummvm|LaunchBox"]="ScummVM"
CANON["sega32x|RetroBat"]="sega32x";     CANON["sega32x|Batocera"]="sega32x";     CANON["sega32x|EmuDeck"]="sega32x";     CANON["sega32x|RetroDeck"]="sega32x";     CANON["sega32x|LaunchBox"]="Sega 32X"
CANON["sega32xjp|RetroBat"]="sega32xjp"; CANON["sega32xjp|Batocera"]="sega32xjp"; CANON["sega32xjp|EmuDeck"]="sega32xjp"; CANON["sega32xjp|RetroDeck"]="sega32xjp"; CANON["sega32xjp|LaunchBox"]="Sega 32X (Japan)"
CANON["sega32xna|RetroBat"]="sega32xna"; CANON["sega32xna|Batocera"]="sega32xna"; CANON["sega32xna|EmuDeck"]="sega32xna"; CANON["sega32xna|RetroDeck"]="sega32xna"; CANON["sega32xna|LaunchBox"]="Sega 32X (North America)"
CANON["segacd|RetroBat"]="segacd";       CANON["segacd|Batocera"]="segacd";       CANON["segacd|EmuDeck"]="segacd";       CANON["segacd|RetroDeck"]="segacd";       CANON["segacd|LaunchBox"]="Sega CD"
CANON["sfc|RetroBat"]="sfc";             CANON["sfc|Batocera"]="sfc";             CANON["sfc|EmuDeck"]="sfc";             CANON["sfc|RetroDeck"]="sfc";             CANON["sfc|LaunchBox"]="Super Famicom"
CANON["sg-1000|RetroBat"]="sg-1000";     CANON["sg-1000|Batocera"]="sg-1000";     CANON["sg-1000|EmuDeck"]="sg-1000";     CANON["sg-1000|RetroDeck"]="sg-1000";     CANON["sg-1000|LaunchBox"]="Sega SG-1000"
CANON["sgb|RetroBat"]="sgb";             CANON["sgb|Batocera"]="sgb";             CANON["sgb|EmuDeck"]="sgb";             CANON["sgb|RetroDeck"]="sgb";             CANON["sgb|LaunchBox"]="Super Game Boy"
CANON["sneshd|RetroBat"]="sneshd";       CANON["sneshd|Batocera"]="sneshd";       CANON["sneshd|EmuDeck"]="sneshd";       CANON["sneshd|RetroDeck"]="sneshd";       CANON["sneshd|LaunchBox"]="Super Nintendo (HD Packs)"
CANON["snesna|RetroBat"]="snesna";       CANON["snesna|Batocera"]="snesna";       CANON["snesna|EmuDeck"]="snesna";       CANON["snesna|RetroDeck"]="snesna";       CANON["snesna|LaunchBox"]="Super Nintendo (North America)"
CANON["solarus|RetroBat"]="solarus";     CANON["solarus|Batocera"]="solarus";     CANON["solarus|EmuDeck"]="solarus";     CANON["solarus|RetroDeck"]="solarus";     CANON["solarus|LaunchBox"]="Solarus"
CANON["spectravideo|RetroBat"]="spectravideo"; CANON["spectravideo|Batocera"]="spectravideo"; CANON["spectravideo|EmuDeck"]="spectravideo"; CANON["spectravideo|RetroDeck"]="spectravideo"; CANON["spectravideo|LaunchBox"]="Spectravideo"
CANON["satellaview|RetroBat"]="satellaview"; CANON["satellaview|Batocera"]="satellaview"; CANON["satellaview|EmuDeck"]="satellaview"; CANON["satellaview|RetroDeck"]="satellaview"; CANON["satellaview|LaunchBox"]="Nintendo Satellaview"
CANON["steam|RetroBat"]="steam";         CANON["steam|Batocera"]="steam";         CANON["steam|EmuDeck"]="steam";         CANON["steam|RetroDeck"]="steam";         CANON["steam|LaunchBox"]="Steam"
CANON["stratagus|RetroBat"]="stratagus"; CANON["stratagus|Batocera"]="stratagus"; CANON["stratagus|EmuDeck"]="stratagus"; CANON["stratagus|RetroDeck"]="stratagus"; CANON["stratagus|LaunchBox"]="Stratagus"
CANON["sufami|RetroBat"]="sufami";       CANON["sufami|Batocera"]="sufami";       CANON["sufami|EmuDeck"]="sufami";       CANON["sufami|RetroDeck"]="sufami";       CANON["sufami|LaunchBox"]="Sufami Turbo"
CANON["supergrafx|RetroBat"]="supergrafx"; CANON["supergrafx|Batocera"]="supergrafx"; CANON["supergrafx|EmuDeck"]="supergrafx"; CANON["supergrafx|RetroDeck"]="supergrafx"; CANON["supergrafx|LaunchBox"]="NEC SuperGrafx"
CANON["supervision|RetroBat"]="supervision"; CANON["supervision|Batocera"]="supervision"; CANON["supervision|EmuDeck"]="supervision"; CANON["supervision|RetroDeck"]="supervision"; CANON["supervision|LaunchBox"]="Watara Supervision"
CANON["switch|RetroBat"]="switch";       CANON["switch|Batocera"]="switch";       CANON["switch|EmuDeck"]="switch";       CANON["switch|RetroDeck"]="switch";       CANON["switch|LaunchBox"]="Nintendo Switch"
CANON["symbian|RetroBat"]="symbian";     CANON["symbian|Batocera"]="symbian";     CANON["symbian|EmuDeck"]="symbian";     CANON["symbian|RetroDeck"]="symbian";     CANON["symbian|LaunchBox"]="Symbian"
CANON["tanodragon|RetroBat"]="tanodragon"; CANON["tanodragon|Batocera"]="tanodragon"; CANON["tanodragon|EmuDeck"]="tanodragon"; CANON["tanodragon|RetroDeck"]="tanodragon"; CANON["tanodragon|LaunchBox"]="Tandy TRS-80 Dragon"
CANON["tg-cd|RetroBat"]="tg-cd";         CANON["tg-cd|Batocera"]="tg-cd";         CANON["tg-cd|EmuDeck"]="tg-cd";         CANON["tg-cd|RetroDeck"]="tg-cd";         CANON["tg-cd|LaunchBox"]="TurboGrafx-CD"
CANON["tg16|RetroBat"]="tg16";           CANON["tg16|Batocera"]="tg16";           CANON["tg16|EmuDeck"]="tg16";           CANON["tg16|RetroDeck"]="tg16";           CANON["tg16|LaunchBox"]="TurboGrafx-16"
CANON["ti99|RetroBat"]="ti99";           CANON["ti99|Batocera"]="ti99";           CANON["ti99|EmuDeck"]="ti99";           CANON["ti99|RetroDeck"]="ti99";           CANON["ti99|LaunchBox"]="TI-99/4A"
CANON["tic80|RetroBat"]="tic80";         CANON["tic80|Batocera"]="tic80";         CANON["tic80|EmuDeck"]="tic80";         CANON["tic80|RetroDeck"]="tic80";         CANON["tic80|LaunchBox"]="TIC-80"
CANON["to8|RetroBat"]="to8";             CANON["to8|Batocera"]="to8";             CANON["to8|EmuDeck"]="to8";             CANON["to8|RetroDeck"]="to8";             CANON["to8|LaunchBox"]="Thomson TO8"
CANON["trs-80|RetroBat"]="trs-80";       CANON["trs-80|Batocera"]="trs-80";       CANON["trs-80|EmuDeck"]="trs-80";       CANON["trs-80|RetroDeck"]="trs-80";       CANON["trs-80|LaunchBox"]="TRS-80"
CANON["uzebox|RetroBat"]="uzebox";       CANON["uzebox|Batocera"]="uzebox";       CANON["uzebox|EmuDeck"]="uzebox";       CANON["uzebox|RetroDeck"]="uzebox";       CANON["uzebox|LaunchBox"]="Uzebox"
CANON["vectrex|RetroBat"]="vectrex";     CANON["vectrex|Batocera"]="vectrex";     CANON["vectrex|EmuDeck"]="vectrex";     CANON["vectrex|RetroDeck"]="vectrex";     CANON["vectrex|LaunchBox"]="GCE Vectrex"
CANON["vic20|RetroBat"]="vic20";         CANON["vic20|Batocera"]="vic20";         CANON["vic20|EmuDeck"]="vic20";         CANON["vic20|RetroDeck"]="vic20";         CANON["vic20|LaunchBox"]="Commodore VIC-20"
CANON["videopac|RetroBat"]="videopac";   CANON["videopac|Batocera"]="videopac";   CANON["videopac|EmuDeck"]="videopac";   CANON["videopac|RetroDeck"]="videopac";   CANON["videopac|LaunchBox"]="Philips Videopac"
CANON["virtualboy|RetroBat"]="virtualboy"; CANON["virtualboy|Batocera"]="virtualboy"; CANON["virtualboy|EmuDeck"]="virtualboy"; CANON["virtualboy|RetroDeck"]="virtualboy"; CANON["virtualboy|LaunchBox"]="Nintendo Virtual Boy"
CANON["vsmile|RetroBat"]="vsmile";       CANON["vsmile|Batocera"]="vsmile";       CANON["vsmile|EmuDeck"]="vsmile";       CANON["vsmile|RetroDeck"]="vsmile";       CANON["vsmile|LaunchBox"]="VTech V.Smile"
CANON["wasm4|RetroBat"]="wasm4";         CANON["wasm4|Batocera"]="wasm4";         CANON["wasm4|EmuDeck"]="wasm4";         CANON["wasm4|RetroDeck"]="wasm4";         CANON["wasm4|LaunchBox"]="WASM-4"
CANON["wii|RetroBat"]="wii";             CANON["wii|Batocera"]="wii";             CANON["wii|EmuDeck"]="wii";             CANON["wii|RetroDeck"]="wii";             CANON["wii|LaunchBox"]="Nintendo Wii"
CANON["wiiu|RetroBat"]="wiiu";           CANON["wiiu|Batocera"]="wiiu";           CANON["wiiu|EmuDeck"]="wiiu";           CANON["wiiu|RetroDeck"]="wiiu";           CANON["wiiu|LaunchBox"]="Nintendo Wii U"
CANON["windows|RetroBat"]="windows";     CANON["windows|Batocera"]="windows";     CANON["windows|EmuDeck"]="windows";     CANON["windows|RetroDeck"]="windows";     CANON["windows|LaunchBox"]="Windows"
CANON["wonderswan|RetroBat"]="wonderswan"; CANON["wonderswan|Batocera"]="wonderswan"; CANON["wonderswan|EmuDeck"]="wonderswan"; CANON["wonderswan|RetroDeck"]="wonderswan"; CANON["wonderswan|LaunchBox"]="Bandai WonderSwan"
CANON["wonderswancolor|RetroBat"]="wonderswancolor"; CANON["wonderswancolor|Batocera"]="wonderswancolor"; CANON["wonderswancolor|EmuDeck"]="wonderswancolor"; CANON["wonderswancolor|RetroDeck"]="wonderswancolor"; CANON["wonderswancolor|LaunchBox"]="Bandai WonderSwan Color"
CANON["x1|RetroBat"]="x1";               CANON["x1|Batocera"]="x1";               CANON["x1|EmuDeck"]="x1";               CANON["x1|RetroDeck"]="x1";               CANON["x1|LaunchBox"]="Sharp X1"
CANON["x68000|RetroBat"]="x68000";       CANON["x68000|Batocera"]="x68000";       CANON["x68000|EmuDeck"]="x68000";       CANON["x68000|RetroDeck"]="x68000";       CANON["x68000|LaunchBox"]="Sharp X68000"
CANON["xbox|RetroBat"]="xbox";           CANON["xbox|Batocera"]="xbox";           CANON["xbox|EmuDeck"]="xbox";           CANON["xbox|RetroDeck"]="xbox";           CANON["xbox|LaunchBox"]="Microsoft Xbox"
CANON["xbox360|RetroBat"]="xbox360";     CANON["xbox360|Batocera"]="xbox360";     CANON["xbox360|EmuDeck"]="xbox360";     CANON["xbox360|RetroDeck"]="xbox360";     CANON["xbox360|LaunchBox"]="Microsoft Xbox 360"
CANON["xbla|RetroBat"]="xbla";           CANON["xbla|Batocera"]="xbla";           CANON["xbla|EmuDeck"]="xbla";           CANON["xbla|RetroDeck"]="xbla";           CANON["xbla|LaunchBox"]="Xbox Live Arcade"
CANON["zmachine|RetroBat"]="zmachine";   CANON["zmachine|Batocera"]="zmachine";   CANON["zmachine|EmuDeck"]="zmachine";   CANON["zmachine|RetroDeck"]="zmachine";   CANON["zmachine|LaunchBox"]="Z-Machine (Infocom)"
CANON["zx81|RetroBat"]="zx81";           CANON["zx81|Batocera"]="zx81";           CANON["zx81|EmuDeck"]="zx81";           CANON["zx81|RetroDeck"]="zx81";           CANON["zx81|LaunchBox"]="Sinclair ZX81"
CANON["zxspectrum|RetroBat"]="zxspectrum"; CANON["zxspectrum|Batocera"]="zxspectrum"; CANON["zxspectrum|EmuDeck"]="zxspectrum"; CANON["zxspectrum|RetroDeck"]="zxspectrum"; CANON["zxspectrum|LaunchBox"]="Sinclair ZX Spectrum"

# Make RGS mirror RetroBat automatically
for k in "${!CANON[@]}"; do
  canon="${k%%|*}"; fe="${k##*|}"
  if [[ "$fe" == "RetroBat" ]]; then
    CANON["$canon|RGS"]="${CANON[$k]}"
  fi
done

# Build lookup index for -> canonical
declare -A CANON_INDEX
to_compact() { tr -d ' _-' | tr '[:upper:]' '[:lower:]'; }
for k in "${!CANON[@]}"; do
  canon="${k%%|*}"; fe="${k##*|}"; name="${CANON[$k]}"
  low="$(printf '%s' "$name" | to_compact)"
  CANON_INDEX["$fe|$low"]="$canon"
done

to_canonical() {
  local fe="$1" actual="$2"
  [[ -z "$actual" ]] && { printf '%s' ""; return; }
  local compact; compact="$(printf '%s' "$actual" | to_compact)"
  local key="$fe|$compact"
  if [[ -n "${CANON_INDEX[$key]:-}" ]]; then
    printf '%s' "${CANON_INDEX[$key]}"; return
  fi
  # fallback scan
  for k in "${!CANON[@]}"; do
    local canon="${k%%|*}" fe2="${k##*|}" n="${CANON[$k]}"
    [[ "$fe2" == "$fe" ]] || continue
    if [[ "$(printf '%s' "$n" | to_compact)" == "$compact" ]]; then
      printf '%s' "$canon"; return
    fi
  done
  printf '%s' ""
}

from_canonical() {
  local fe="$1" canon="$2"
  local key="$canon|$fe"
  if [[ -n "${CANON[$key]:-}" ]]; then
    printf '%s' "${CANON[$key]}"; return
  fi
  printf '%s' ""
}

# ------------- schemas -------------
IMAGE_TYPES=("screenshot" "marquee" "boxfront")

get_source_schema() {
  local fe="$1"
  case "$fe" in
    LaunchBox)
      cat <<'EOS'
SourceMode=Centralized
ImageTypes="screenshot marquee boxfront"
VideoPresent=1
IMG_screenshot_MatchMode=Plain
IMG_screenshot_Suffix=
IMG_screenshot_Folder=
IMG_screenshot_Subfolders="Screenshots"
IMG_marquee_MatchMode=Plain
IMG_marquee_Suffix=
IMG_marquee_Folder=
IMG_marquee_Subfolders="Marquees"
IMG_boxfront_MatchMode=Plain
IMG_boxfront_Suffix=
IMG_boxfront_Folder=
IMG_boxfront_Subfolders="Covers|Box - Front"
VID_MatchMode=Plain
VID_Suffix=
VID_Folder=
EOS
      ;;
    EmuDeck|RetroDeck)
      cat <<'EOS'
SourceMode=Flat
ImageTypes="screenshot marquee boxfront"
VideoPresent=1
IMG_screenshot_MatchMode=Suffix
IMG_screenshot_Suffix=image
IMG_screenshot_Folder=screenshots
IMG_screenshot_Subfolders=
IMG_marquee_MatchMode=Suffix
IMG_marquee_Suffix=marquee
IMG_marquee_Folder=marquees
IMG_marquee_Subfolders=
IMG_boxfront_MatchMode=Suffix
IMG_boxfront_Suffix=thumb
IMG_boxfront_Folder=covers
IMG_boxfront_Subfolders=
VID_MatchMode=Suffix
VID_Suffix=video
VID_Folder=videos
EOS
      ;;
    RGS)
      cat <<'EOS'
SourceMode=Flat
ImageTypes="screenshot marquee boxfront"
VideoPresent=1
IMG_screenshot_MatchMode=Suffix
IMG_screenshot_Suffix=image
IMG_screenshot_Folder="media/images"
IMG_screenshot_Subfolders=
IMG_marquee_MatchMode=Suffix
IMG_marquee_Suffix=marquee
IMG_marquee_Folder="media/marquee"
IMG_marquee_Subfolders=
IMG_boxfront_MatchMode=Suffix
IMG_boxfront_Suffix=thumb
IMG_boxfront_Folder="media/box2d"
IMG_boxfront_Subfolders=
VID_MatchMode=Suffix
VID_Suffix=video
VID_Folder="media/videos"
EOS
      ;;
    *)
      cat <<'EOS'
SourceMode=Flat
ImageTypes="screenshot marquee boxfront"
VideoPresent=1
IMG_screenshot_MatchMode=Suffix
IMG_screenshot_Suffix=image
IMG_screenshot_Folder=images
IMG_screenshot_Subfolders=
IMG_marquee_MatchMode=Suffix
IMG_marquee_Suffix=marquee
IMG_marquee_Folder=images
IMG_marquee_Subfolders=
IMG_boxfront_MatchMode=Suffix
IMG_boxfront_Suffix=thumb
IMG_boxfront_Folder=images
IMG_boxfront_Subfolders=
VID_MatchMode=Suffix
VID_Suffix=video
VID_Folder=videos
EOS
      ;;
  esac
}

get_dest_schema() {
  local fe="$1" local_system_root="$2" local_override="$3"
  local system_name; system_name="$(basename -- "$local_system_root")"
  case "$fe" in
    LaunchBox)
      local games_folder; games_folder="$(dirname -- "$local_system_root")"
      local lb_root; lb_root="$(dirname -- "$games_folder")"
      cat <<EOS
Mode=Centralized
ImagesBase="$lb_root/Images/$system_name"
VideosBase="$lb_root/Videos/$system_name"
ImageTypes="screenshot marquee boxfront"
IMG_screenshot_FilePattern="{rom}{ext}"
IMG_screenshot_Suffix=
IMG_screenshot_Subfolder="Screenshots"
IMG_marquee_FilePattern="{rom}{ext}"
IMG_marquee_Suffix=
IMG_marquee_Subfolder="Marquees"
IMG_boxfront_FilePattern="{rom}{ext}"
IMG_boxfront_Suffix=
IMG_boxfront_Subfolder="Covers"
VideoPresent=1
VID_FilePattern="{rom}{ext}"
VID_Suffix=
VID_Subfolder=
EOS
      ;;
    EmuDeck|RetroDeck)
      [[ -n "$local_override" ]] || err "$fe requires Local Media Path"
      local base="$local_override/downloaded_media/$system_name"
      cat <<EOS
Mode=Centralized
ImagesBase="$base"
VideosBase="$base"
ImageTypes="screenshot marquee boxfront"
IMG_screenshot_FilePattern="{rom}{ext}"
IMG_screenshot_Suffix=
IMG_screenshot_Subfolder="screenshots"
IMG_marquee_FilePattern="{rom}{ext}"
IMG_marquee_Suffix=
IMG_marquee_Subfolder="marquees"
IMG_boxfront_FilePattern="{rom}{ext}"
IMG_boxfront_Suffix=
IMG_boxfront_Subfolder="covers"
VideoPresent=1
VID_FilePattern="{rom}{ext}"
VID_Suffix=
VID_Subfolder="videos"
EOS
      ;;
    RGS)
      local media_base="$local_system_root/media"
      cat <<EOS
Mode=Centralized
ImagesBase="$media_base"
VideosBase="$media_base"
ImageTypes="screenshot marquee boxfront"
IMG_screenshot_FilePattern="{rom}-{suffix}{ext}"
IMG_screenshot_Suffix="image"
IMG_screenshot_Subfolder="images"
IMG_marquee_FilePattern="{rom}-{suffix}{ext}"
IMG_marquee_Suffix="marquee"
IMG_marquee_Subfolder="marquee"
IMG_boxfront_FilePattern="{rom}-{suffix}{ext}"
IMG_boxfront_Suffix="thumb"
IMG_boxfront_Subfolder="box2d"
VideoPresent=1
VID_FilePattern="{rom}-{suffix}{ext}"
VID_Suffix="video"
VID_Subfolder="videos"
EOS
      ;;
    *)
      local images="$local_system_root/images"
      local videos="$local_system_root/videos"
      cat <<EOS
Mode=Flat
ImagesRoot="$images"
VideosRoot="$videos"
ImageTypes="screenshot marquee boxfront"
IMG_screenshot_FilePattern="{rom}-{suffix}{ext}"
IMG_screenshot_Suffix="image"
IMG_marquee_FilePattern="{rom}-{suffix}{ext}"
IMG_marquee_Suffix="marquee"
IMG_boxfront_FilePattern="{rom}-{suffix}{ext}"
IMG_boxfront_Suffix="thumb"
VideoPresent=1
VID_FilePattern="{rom}-{suffix}{ext}"
VID_Suffix="video"
EOS
      ;;
  esac
}

missing_label() {
  local mode="$1" type="$2"
  if [[ "$type" == "video" ]]; then
    [[ "$mode" == "Centralized" && -n "${DST[VID_Subfolder]:-}" ]] && { echo "${DST[VID_Subfolder]}"; return; }
    [[ -n "${DST[VID_Suffix]:-}" ]] && { echo "${DST[VID_Suffix]}"; return; }
    echo "video"; return
  fi
  if [[ "$mode" == "Centralized" ]]; then
    local k="IMG_${type}_Subfolder"
    [[ -n "${DST[$k]:-}" ]] && { echo "${DST[$k]}"; return; }
  fi
  local k="IMG_${type}_Suffix"
  [[ -n "${DST[$k]:-}" ]] && { echo "${DST[$k]}"; return; }
  case "$type" in
    boxfront) echo "covers" ;;
    marquee)  echo "marquees" ;;
    *)        echo "screenshots" ;;
  esac
}

# ------------- main interactive flow -------------
DEST_FE="$(choose_frontend 'Select your destination frontend (the one you are USING):')"
SRC_FE="$(choose_frontend 'Select the source frontend (where the MEDIA is FROM):')"
prompt_paths "$DEST_FE"

SYNC_IMAGES=1
SYNC_VIDEOS=1
echo ""
echo "Sync Images: ON   Sync Videos: ON   (same as GUI default)"

# ------------- engine -------------
missing_report="$LOCAL_ROM_PATH/_missing-media.txt"
: > "$missing_report"

# Build destination system list by scanning local folders
declare -a systems=()
if [[ "$DEST_FE" == "LaunchBox" ]]; then
  if [[ -d "$LOCAL_ROM_PATH/Games" ]]; then
    while IFS= read -r -d '' d; do systems+=("$(basename "$d")"); done \
      < <(find "$LOCAL_ROM_PATH/Games" -mindepth 1 -maxdepth 1 -type d -print0)
  fi
else
  while IFS= read -r -d '' d; do systems+=("$(basename "$d")"); done \
    < <(find "$LOCAL_ROM_PATH" -mindepth 1 -maxdepth 1 -type d -print0)
fi
[[ ${#systems[@]} -gt 0 ]] || err "No system folders found under $LOCAL_ROM_PATH for $DEST_FE."

# Load source schema
declare -A SRC
while IFS='=' read -r k v; do
  [[ -z "$k" ]] && continue
  v="${v%\"}"; v="${v#\"}"
  SRC["$k"]="$v"
done < <(get_source_schema "$SRC_FE")

# Prepare real arrays for image pools
for t in "${IMAGE_TYPES[@]}"; do
  declare -a "POOL_$t=()"
done

# Accumulate missing lines per system
declare -A MISS

for system in "${systems[@]}"; do
  log ""
  log "Processing [$system]…"

  if [[ "$DEST_FE" == "LaunchBox" ]]; then
    local_system_root="$LOCAL_ROM_PATH/Games/$system"
  else
    local_system_root="$LOCAL_ROM_PATH/$system"
  fi
  [[ -d "$local_system_root" ]] || { log "  Skipping (no folder)"; continue; }

  canonical="$(to_canonical "$DEST_FE" "$system")"
  if [[ -n "$canonical" ]]; then
    source_system="$(from_canonical "$SRC_FE" "$canonical")"
  else
    source_system="$system"
  fi
  if [[ -z "$source_system" ]]; then
    log "  No mapping for '$system' ($DEST_FE -> $SRC_FE). Skipping."
    continue
  fi

  # Destination schema
  declare -A DST
  while IFS='=' read -r k v; do
    [[ -z "$k" ]] && continue
    v="${v%\"}"; v="${v#\"}"
    DST["$k"]="$v"
  done < <(get_dest_schema "$DEST_FE" "$local_system_root" "${LOCAL_MEDIA_PATH:-}")

  # Ensure dest folders
  if [[ "${DST[Mode]}" == "Centralized" ]]; then
    [[ -n "${DST[ImagesBase]:-}" ]] && ensure_dir "${DST[ImagesBase]}"
    [[ -n "${DST[VideosBase]:-}" ]] && ensure_dir "${DST[VideosBase]}"
    IFS=' ' read -r -a itypes <<< "${DST[ImageTypes]}"
    for t in "${itypes[@]}"; do
      sub="${DST[IMG_${t}_Subfolder]:-}"
      [[ -n "$sub" && -n "${DST[ImagesBase]:-}" ]] && ensure_dir "${DST[ImagesBase]}/$sub"
    done
  else
    [[ -n "${DST[ImagesRoot]:-}" ]] && ensure_dir "${DST[ImagesRoot]}"
    [[ -n "${DST[VideosRoot]:-}" ]] && ensure_dir "${DST[VideosRoot]}"
  fi

  # Source paths
  if [[ "${SRC[SourceMode]}" == "Centralized" ]]; then
    src_images_base="$REMOTE_MEDIA_PATH/Images/$source_system"
    src_videos_base="$REMOTE_MEDIA_PATH/Videos/$source_system"
  else
    src_system_root="$REMOTE_MEDIA_PATH/$source_system"
  fi

  # ROM dict
  declare -A ROM_CLEAN=()
  while IFS= read -r -d '' f; do
    base="$(base_noext "$f")"
    ROM_CLEAN["$base"]="$(clean_name "$base")"
  done < <(find "$local_system_root" -mindepth 1 -maxdepth 1 -type f -print0)

  # Pools: images (fill real arrays via namerefs)
  if [[ "$SYNC_IMAGES" -eq 1 ]]; then
    IFS=' ' read -r -a stypes <<< "${SRC[ImageTypes]}"
    for t in "${stypes[@]}"; do
      declare -n POOL="POOL_$t"
      POOL=()
      if [[ "${SRC[SourceMode]}" == "Centralized" ]]; then
        IFS='|' read -r -a subs <<< "${SRC[IMG_${t}_Subfolders]:-}"
        for sub in "${subs[@]}"; do
          [[ -z "$sub" ]] && continue
          dir="$src_images_base/$sub"
          while IFS= read -r -d '' f; do POOL+=("$f"); done < <(list_files_0 "$dir")
        done
      else
        folder="${SRC[IMG_${t}_Folder]:-images}"
        dir="$src_system_root/$folder"
        while IFS= read -r -d '' f; do POOL+=("$f"); done < <(list_files_0 "$dir")
      fi
    done
  fi

  # Pool: videos (real array)
  VIDEO_POOL=()
  if [[ "$SYNC_VIDEOS" -eq 1 && "${SRC[VideoPresent]}" == "1" && "${DST[VideoPresent]}" == "1" ]]; then
    if [[ "${SRC[SourceMode]}" == "Centralized" ]]; then
      while IFS= read -r -d '' f; do VIDEO_POOL+=("$f"); done < <(list_files_0 "$src_videos_base")
    else
      vfolder="${SRC[VID_Folder]:-videos}"
      while IFS= read -r -d '' f; do VIDEO_POOL+=("$f"); done < <(list_files_0 "$src_system_root/$vfolder")
    fi
  fi

  # iterate ROMs
  for rom_base in "${!ROM_CLEAN[@]}"; do
    clean="${ROM_CLEAN[$rom_base]}"
    declare -a miss=()

    # images
    if [[ "$SYNC_IMAGES" -eq 1 ]]; then
      for t in "${IMAGE_TYPES[@]}"; do
        # skip types not shared by source/dest
        [[ " ${SRC[ImageTypes]} " == *" $t "* ]] || continue
        [[ " ${DST[ImageTypes]} " == *" $t "* ]] || continue

        suf="${SRC[IMG_${t}_Suffix]:-}"
        mmode="${SRC[IMG_${t}_MatchMode]:-Plain}"

        declare -n POOL="POOL_$t"
        pool_files=("${POOL[@]}")
        match=""
        if [[ ${#pool_files[@]} -gt 0 ]]; then
          match="$(find_match "$mmode" "$suf" "$clean" "${pool_files[@]}" || true)"
        fi

        if [[ -n "$match" ]]; then
          ext="$(ext_withdot "$match")"
          dpat="${DST[IMG_${t}_FilePattern]}"
          dsuf="${DST[IMG_${t}_Suffix]:-}"
          dname="$(build_dest_filename "$dpat" "$rom_base" "$ext" "$dsuf")"

          if [[ "${DST[Mode]}" == "Centralized" ]]; then
            sub="${DST[IMG_${t}_Subfolder]}"
            dest="${DST[ImagesBase]}/$sub/$dname"
          else
            dest="${DST[ImagesRoot]}/$dname"
          fi
          if [[ ! -e "$dest" ]]; then
            ensure_dir "$(dirname -- "$dest")"
            cp -n -- "$match" "$dest" || cp -- "$match" "$dest"
          fi
        else
          miss+=("$(missing_label "${DST[Mode]}" "$t")")
        fi
      done
    fi

    # video
    if [[ "$SYNC_VIDEOS" -eq 1 && "${SRC[VideoPresent]}" == "1" && "${DST[VideoPresent]}" == "1" ]]; then
      vpool=("${VIDEO_POOL[@]}")
      vsuf="${SRC[VID_Suffix]:-}"
      vmode="${SRC[VID_MatchMode]:-Plain}"
      vmatch=""
      if [[ ${#vpool[@]} -gt 0 ]]; then
        vmatch="$(find_match "$vmode" "$vsuf" "$clean" "${vpool[@]}" || true)"
      fi
      if [[ -n "$vmatch" ]]; then
        vext="$(ext_withdot "$vmatch")"
        vpat="${DST[VID_FilePattern]}"
        vsfx="${DST[VID_Suffix]:-}"
        vname="$(build_dest_filename "$vpat" "$rom_base" "$vext" "$vsfx")"

        if [[ "${DST[Mode]}" == "Centralized" ]]; then
          vfolder="${DST[VideosBase]}"
          [[ -n "${DST[VID_Subfolder]:-}" ]] && vfolder="$vfolder/${DST[VID_Subfolder]}"
          dest="$vfolder/$vname"
        else
          dest="${DST[VideosRoot]}/$vname"
        fi
        if [[ ! -e "$dest" ]]; then
          ensure_dir "$(dirname -- "$dest")"
          cp -n -- "$vmatch" "$dest" || cp -- "$vmatch" "$dest"
        fi
      else
        miss+=("$(missing_label "${DST[Mode]}" "video")")
      fi
    fi

    if [[ ${#miss[@]} -gt 0 ]]; then
      # unique + sorted labels on one line
      mapfile -t uniq < <(printf '%s\n' "${miss[@]}" | sed '/^$/d' | sort -u)
      printf '[%s]\n' "$system" >>"$missing_report"
      printf '%s (%s)\n\n' "$rom_base" "$(IFS=', '; echo "${uniq[*]}")" >>"$missing_report"
    fi
  done
done

log ""
if [[ -s "$missing_report" ]]; then
  log "Some media is missing. See: $missing_report"
else
  rm -f -- "$missing_report"
  log "All media present!"
fi