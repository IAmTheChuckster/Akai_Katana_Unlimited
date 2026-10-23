---
name: "akai-katana-unlimited-build"
description: "Rebuild or extend the Akai Katana Unlimited patch (SH-3 boot-hook routines, ARCADE/UNLIMITED mode menu, web and Python patchers, MiSTer MRA) from an original akatana dump and test it in MAME."
---

# Akai Katana Unlimited: build and extend

Recreates and extends https://github.com/IAmTheChuckster/Akai_Katana_Unlimited from the user's own
`akatana.zip`. **Never put ROM data in the repo, the web page or any shared output**; only new code,
new text and changed-byte tables.

## 0. Inputs and expected results
| File | CRC32 | Notes |
|---|---|---|
| u4 | 613fd380 | program, 2010/ 8/13 MASTER VER. (patched) |
| u2, u23, u24 | 89a2e1a5, 34a67e24, 10760fed | copied unchanged |

Output: patched `u4` (CRC32 is in `tools/build.py` and the README; `c229869a` at the time of writing),
romset `akatanaultd.zip` = patched u4 + u2/u23/u24, MiSTer `Akai Katana Unlimited.mra`.

## 1. Set up
1. Clone the repo; ask the user for `akatana.zip` and never commit it (`.gitignore` covers u2/u4/u23/u24).
2. MAME 0.289 test env: use the `cv1000-learn-game` skill. CV1000-D board: 16 MB RAM 0x0C000000-0x0CFFFFFF.
   Harness `lua/akatana_harness.lua` via `scripts/ak.sh` (AK_MODE boot|run, AK_STATE, AK_SCHED, AK_FRAMES,
   AK_SAVES, AK_DUMP, AK_SNAP/AK_SNAPEVERY, AK_RAMAT, AK_HOLD, AK_POKE). Use a separate ROM dir
   (`roms_gold`) and work dir (`work_gold`) for the patched build; rebuild the title and stage-1 states
   (both modes x Tsubaki/Botan/Shion) after every build, because save states keep the old code in RAM.
3. Toolchain: `sh-elf-as`/`sh-elf-objcopy` (binutils for SH), Python 3. `make U4=<original u4>` assembles
   `src/goldpatch.s` and runs `tools/build.py`, which writes `build/u4`.

## 2. How the patch works
- u4 is 16-bit word-swapped. The program runs from RAM after the boot copy. `tools/build.py` puts the
  assembled blob at ROM 0x3F0000 (free 0xFF space, CPU address 0xA03F0000) and changes the boot literal
  at 0x1D4 (0x0C1DE164) to 0xA03F0000, so our hook runs first and then jumps on to 0x0C1DE164.
- **Gotcha:** 0x0C1DE164 clears bss after the hook. Never keep state there that must survive boot;
  original values for ARCADE MODE are hard-coded in ROM tables.
- The hook writes the **permanent** patches (word table at 0x6C0, long table at 0x1000) through P2
  addresses (0xAC...), copies the warning text (0x700, from `src/warntext.s`), and clears the menu vars.
- **Switchable** patches (word table 0x300 / originals 0x360, long table 0x600 / originals 0x680) are applied at
  every game start by the scene-change wrapper (stgclr @0x4E0, hooked at 0x0C1F0F0C), writing either the
  UNLIMITED values or the originals depending on the mode. Runtime writes use P1 addresses (0x8C...).
- Menu vars at 0x0C7FF000: +0 cursor, +4 previous input, +8 mode in use, +12 replay toggle.
- SH-3 `mov #imm`/`add #imm` are signed 8-bit: values above 127 silently wrap (use extu.b or a register).
- When adding a table entry, update SW_WN/SW_LN/PM_WN/PM_LN and check the `.org` areas don't overlap.

## 3. Features and where they live (see `src/goldpatch.s` for the code)
| Feature | Edit |
|---|---|
| Mode menu | Title rank/score block 0x0C221F30 → jmp via literal 0x0C2220E8 → menu @0xC00 (strings 0xE00-0xE40). Print 0C1DD12C, credits 0C1E0D7C, P1 held input 0C1DC9BE. ARCADE = original game. |
| Gold collected at once | Orbit entry random() call 0x0C2299D8 → chooser @0x140; 0x0C22989C/0x0C2298A0 words. |
| HIT counts collected gold, resets per stage | No AddHit at spawn (0x0C226F34 nop); timer clears 0x0C27C724/0x0C27B666 nop; reset in stgclr. |
| Gold = medal × HIT ÷ 10 | Item collect AddScore call literal 0x0C22A104 → wrapper @0x480. |
| Close-range 100 medal → 1,000 | SpawnItem per-kind setup 0x0C226F14 → wrapper @0x400 (50 px of hitbox). |
| Leaving spirit form free | 0x0C217D9C = 0 (was 0x640). |
| Bullets slow near orb | Bullet manager 0x0C1FF3D2-DC → orb-slow @0x200 (24 px, slow % at bullet+0x138). |
| Energy balls follow into spirit form, collected on exit | Energy init 0x0C227F50 → emain @0x280; 0x0C22994E nop. |
| Triple bullets | Bullet create (0x0C2000D0) calls 0x0C1FFBB4/0x0C1FFCD4 → tripler @0xF00 (copies 5 and 10 frames back; revenge type 0x4A and full pool skipped). |
| 1.5x volleys | Emitter processor literal 0x0C1FF38C → replay @0x1100 (every other new emitter re-queued 20 frames later; emitters are 148-byte records at base+0x5CC80, count at base+0x6ED90, base @0x0C4C65AC). |
| Busy guard | `hot`: live bullet count at base+0x5CC70 > BUSY (900) → no extras. |
| Enemy pool 999 → 2400 | Pool moved to 0x0CD00000, in-use table 0x0CD26000 (literals 0x0C207144/A34/140/148/A24/EBC, words 0x0C207A12/126). Fixes the stage-1-boss "enemy/enemy.cpp" assert (line 0x5FF). |
| Shion double energy | Item collect AddEnergy literal 0x0C22A2E4 → @0x1200 (pilot at 0x0C7E8658: 0 Tsubaki, 1 Botan, 2 Shion). |
| Boot screens | `tools/warntext.py` → `src/warntext.s` (Japan 8×40 slots at 0x0C3042D4, date line 0x0C304434, export 13×30 at 0x0C304454); memory-check date 0x0C304158/C, title 0x0C21F734 → string @0xE40. |

## 4. Test
- The game's asserts stop the game and show the error on screen while the music keeps playing; they are
  not reliably in error.log. Always check snapshots, and watch the in-game frame counter 0x0C7E664C for stalls.
- Full-game check: from each `s1_lim_<pilot>` state, run ~150,000 frames with a weave + auto-fire schedule,
  holding invulnerability `l:0c7e87c8=3c` and lives `l:0c7e8630=12c0`; dump 0x0C7E664C and the stage
  index 0x0C7E669C. All six stages should pass and the stage index return to 0 (ending → ranking).
- Kill emulators with `pkill -x cv1k_ak` (not `pkill -f`, which matches the shell itself).

## 5. Release
1. `make U4=<original u4>`; update the expected CRC in `tools/build.py`.
2. `python3 tools/web/diff.py <orig u4> build/u4 > patch.json`, then
   `python3 tools/web/gen.py patch.json <crc>` (writes `index.html` and the .mra) and
   `python3 tools/web/genpy.py patch.json <crc>` (writes `patch.py`). Test both patchers give the CRC.
3. Write a plain-language entry in the README Change Notes; push to main (the user's default branch)
   unless the user asks for a branch. The web patcher is served by GitHub Pages from main.
