# Akai Katana Unlimited

A gameplay patch for Akai Katana (2010/ 8/13 MASTER VER.)<br>
This repository holds only source, tools and notes. **No ROM data is included**; you patch your own legally owned dump.

## About this project
Why did I make this? Because it's fun and for my own personal research to see the capabilities of Claude.<br>
While Claude was used I put effort in making sure there are balanced gameplay.<br>
I did all the testing and planning.

## Change Notes

### Mode select
- After inserting a coin, the title screen shows **ARCADE MODE** and **UNLIMITED** where the rank and high-score lines were. Pick one with up/down and press start.
- **ARCADE MODE** is the original game, untouched. **UNLIMITED** turns on every gameplay change below.

### UNLIMITED gameplay changes
- **Triple bullets:** every normal enemy shot comes as a trailing line of three bullets on the same path.
- **Faster enemy fire:** enemies attack about 1.5x as often.
- **Bullets slow down near your orb:** enemy bullets close to the orb move at half speed.
- **Gold is collected right away:** gold no longer circles you until spirit form ends; it flies straight to you.
- **Gold is worth more with a high HIT count:** each gold piece scores 10% of its medal value times your HIT count.
- **HIT counts collected gold** and keeps counting through the whole stage; it resets at the start of each stage.
- **Close-range medals:** a 100 medal that appears right next to you becomes a 1,000 medal.
- **Leaving spirit form early is free:** you keep the energy you have left instead of losing 1,600.
- **Energy balls follow you into spirit form,** don't expire while you're in it, and are collected automatically when you go back to ship mode.
- **Shion's pen collects energy twice as fast.**
- **Revenge bullets** work as in the original game (spirit form only).

### Fixes
- Fixed a freeze at the stage 1 boss ("enemy/enemy.cpp" error with the music still playing). The game ran out of room for enemy objects; that room has been more than doubled. Tested through to the ending with all three characters.
- Extra bullets pause when the screen is extremely full, so the game's own bullet limit is never reached.

### Screens
- New boot warning screen: an unofficial-project notice and "HAVE FUN!!!", with the date line `2026/10/23 UNLIMITED` (both centred).
- The memory-check screen reads **AKAI KATANA UNLIMITED** and `2026/10/23`.

## Patching the game

You need your own dump of the original game: `akatana.zip` with the 2010/ 8/13 MASTER VER. program ROM (u4, CRC32 `613fd380`). No ROM data is included here.

### With the web patcher (easiest)
Open the **[Web Patcher](https://iamthechuckster.github.io/Akai_Katana_Unlimited/)** (`index.html`) and drop in your `akatana.zip`. It checks the file names and CRCs, builds the patched files automatically, and lets you download just the patched files or a complete `akatanaultd.zip` romset. Everything runs in your browser; nothing is uploaded.

### With Python
Needs Python 3, `make`, and the SuperH binutils (`sh-elf-as`, `sh-elf-objcopy`).
1. Clone or download this repository.
2. Copy your original `u4` (from `akatana.zip`) into the repository folder.
3. Run `make U4=u4`. This assembles the patch and writes the patched ROM to `build/u4`, printing its CRC32 (should be `c229869a`).
4. Put `build/u4` into a copy of your `akatana.zip` in place of the original u4 (keep a backup of the original).

## Testing
This patch was tested with MAME 0.289 and [CV1k core for the MiSTer FPGA by Raki](https://www.patreon.com/c/ikamusume/posts)<br>
It may even work on a PCB but do so on your own risk.

## Credits

- [IAmTheChuckster](https://github.com/IAmTheChuckster)  project, testing
- [Claude](https://claude.ai) (Anthropic)  reverse engineering and patcher code
- Tested on the CV1k core for the MiSTer FPGA by [Raki](https://www.patreon.com/c/ikamusume/posts)

## Disclaimer

This repository contains a fan-made patch for research and technical analysis. The repository does not intentionally distribute the original game ROM, executable, or game assets. Users must obtain their own copy of the original game. This project is unofficial and is not affiliated with, endorsed by, or authorized by CAVE. All rights to the original game and its associated intellectual property remain with their respective rights holders. No license to third-party copyrighted material is granted by this repository.
