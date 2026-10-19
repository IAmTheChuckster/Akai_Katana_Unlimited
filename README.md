# Akai Katana Unlimited

A gameplay patch for Akai Katana (2010/ 8/13 MASTER VER.)<br>
This repository holds only source, tools and notes. **No ROM data is included**; you patch your own dump.

## About this project
Why did I make this? Because it's fun and for my own personal research to see the capabilities of Claude.

## What it changes

Spirit form = 念身.

- **Gold is collected automatically.** Gold no longer circles the ship until spirit form ends. As soon as a piece has a player to fly to, it goes to the release state and is collected.
- **HIT counts collected gold.** The +1 HIT now happens when a gold piece is collected, not when it spawns.
- **HIT resets each stage.** The game's own clears (3 seconds after the last hit) are disabled, so HIT keeps counting through a stage; it goes back to 0 when a game starts and when the next stage begins (scene change at `0C1F0E10`).

- **Leaving spirit form early is free.** Pressing the spirit button again used to cost a flat 1,600 energy; now you keep what you have left.
- **Revenge bullets fire with normal shots in ship mode.** In ship mode, every time an enemy fires a normal bullet it also fires a revenge bullet (type `0x4A`) from the same spot in the same direction, and destroying an enemy no longer fires a revenge burst. In spirit form nothing changes: destroyed enemies fire revenge bullets as in the original. Revenge bullets cancel into gold like any other bullet.
- **Bullets slow down near the orb.** Enemy bullets within 24 px of the orb (the familiar ball, whose live position is at `0CA3FBB4`/`0CA3FBB8` for every character) move at half speed, and return to full speed as soon as they leave. This applies in ship and spirit form. It uses the game's own per-bullet slow percentage (bullet+0x138), which the bullet move code applies as velocity × (100 − slow) / 100.
- **Energy balls follow you into spirit form.** Energy balls (item kind 12) circling the orb are no longer sent to be collected when you switch to spirit form. They circle the hitbox instead, the way gold used to (radius about 50 px widening to about 78 px), and go back to the orb when spirit form ends. Their lifetime (item+0xB4; they normally expire about 510 frames after appearing) is paused while you're in spirit form.

- **Close-range medals.** A 100 medal that appears within 50 px of your hitbox (for example from an enemy you destroy up close, or bullets cancelled next to you) becomes a 1,000 medal. Boss gold is still a 10,000 medal.
- **Gold is worth medal × HIT ÷ 10.** Each gold piece collected scores 10% of its medal value (item+0x50: 100 / 1,000 / 10,000) × the HIT count (including this piece). The value is written back into the item before it is added, so the gold score total (`0C27B670`) and the trailing popup (`0C22A320`) show the same amount. Example: a 1,000 medal at 359 HIT adds 35,900.

Side effect: gold no longer ages while orbiting, so a normal gold medal is worth 100 (it used to grow to 1,000 and 10,000); only close-range and boss medals are bigger.

## Patching the game

## Testing
This patch was tested with MAME 0.289 and [CV1k core for the MiSTer FPGA by Raki](https://www.patreon.com/c/ikamusume/posts)<br>
It may even work on a PCB but do so on your own risk.

## Credits

- [FluffyBunnyIronBalls](https://github.com/FluffyBunnyIronBalls) – project, testing
- [Claude](https://claude.ai) (Anthropic) – reverse engineering and patcher code
- Tested on the CV1k core for the MiSTer FPGA by [Raki](https://www.patreon.com/c/ikamusume/posts)

## Disclaimer

This repository contains a fan-made patch for research and technical analysis. The repository does not intentionally distribute the original game ROM, executable, or game assets. Users must obtain their own copy of the original game. This project is unofficial and is not affiliated with, endorsed by, or authorized by CAVE. All rights to the original game and its associated intellectual property remain with their respective rights holders. No license to third-party copyrighted material is granted by this repository.
