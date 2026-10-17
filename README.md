# Akai Katana Gold

A gameplay patch for Akai Katana (Cave, CV1000-D, 2010/ 8/13 MASTER VER., u4 CRC32 `613fd380`).
This repository holds only source, tools and notes. **No ROM data is included**; you patch your own dump.

## Patch it in your browser

Open the web patcher (`index.html`, served by GitHub Pages) and drop your `akatana.zip`. It:

- checks the CRC32 of `u4`, `u2`, `u23` and `u24`;
- builds the patched `u4` (CRC32 `eb8366f2`);
- gives you `akatanagold.zip` (the full set with `u4` replaced), `u4.zip` and the raw `u4`;
- builds `Akai Katana Gold.mra` for MiSTer (ikacore CV1k), filled in with the CRC32s of the files it found, including the new `u4`.

Everything runs locally in the browser; nothing is uploaded. A ready-made `.mra` with the standard CRC32s is in `mister/`.

## What it changes

Spirit form = 念身.

- **Gold is collected automatically.** Gold no longer circles the ship until spirit form ends. As soon as a piece has a player to fly to, it goes to the release state and is collected.
- **HIT counts collected gold.** The +1 HIT now happens when a gold piece is collected, not when it spawns.
- **HIT resets each stage.** The game's own clears (3 seconds after the last hit) are disabled, so HIT keeps counting through a stage; it goes back to 0 when a game starts and when the next stage begins (scene change at `0C1F0E10`).

- **Leaving spirit form early is free.** Pressing the spirit button again used to cost a flat 1,600 energy; now you keep what you have left.
- **Revenge bullets in every mode.** Destroyed enemies fire revenge bullets in ship mode too, whether you kill them with the shot or the laser, with the original count (2 × lives, ×4 for big enemies; not every kill qualifies, as before).
- **Bullets slow down near the orb.** Enemy bullets within 24 px of the orb (the familiar ball, whose live position is at `0CA3FBB4`/`0CA3FBB8` for every character) move at half speed, and return to full speed as soon as they leave. This applies in ship and spirit form. It uses the game's own per-bullet slow percentage (bullet+0x138), which the bullet move code applies as velocity × (100 − slow) / 100.
- **Energy balls follow you into spirit form.** Energy balls (item kind 12) circling the orb are no longer sent to be collected when you switch to spirit form. They circle the hitbox instead, the way gold used to (radius about 50 px widening to about 78 px), and go back to the orb when spirit form ends. Their lifetime (item+0xB4; they normally expire about 510 frames after appearing) is paused while you're in spirit form.

- **Close-range medals.** A 100 medal that appears within 50 px of your hitbox (for example from an enemy you destroy up close, or bullets cancelled next to you) becomes a 1,000 medal. Boss gold is still a 10,000 medal.
- **Gold is worth medal × HIT ÷ 10.** Each gold piece collected scores 10% of its medal value (item+0x50: 100 / 1,000 / 10,000) × the HIT count (including this piece). The value is written back into the item before it is added, so the gold score total (`0C27B670`) and the trailing popup (`0C22A320`) show the same amount. Example: a 1,000 medal at 359 HIT adds 35,900.

Side effect: gold no longer ages while orbiting, so a normal gold medal is worth 100 (it used to grow to 1,000 and 10,000); only close-range and boss medals are bigger.

## How it works

The main program is stored compressed in u4 and unpacked into RAM at boot, so the code can't be edited in the ROM directly. Instead:

1. The boot code's call to `0x0C1DE164` (literal at u4 `0x1D4`) is pointed at a hook in u4's free space (`0x3F0000`, CPU `0xA03F0000`).
2. The hook writes the patches into RAM (through P2 uncached addresses), then continues to `0x0C1DE164`.

| RAM address | Original | New | Effect |
|---|---|---|---|
| `0C2299D8` | `0C1E4190` (random) | `A03F0140` | orbit entry calls our chooser. It returns the random number as before, plus the state in r2: 4 (release) for gold (item kind 0–2) that already has a target player (item+0x110 ≥ 0), copying the target to item+0x114 like the game's own release code; 2 (orbit) otherwise |
| `0C22989C` | `E402` mov #2,r4 | `6423` mov r2,r4 | store the chosen state |
| `0C2298A0` | `E602` mov #2,r6 | `6623` mov r2,r6 | dispatch the chosen state this frame |
| `0C226F34` | `4A0B` jsr @r10 (AddHit) | `0009` nop | no HIT on spawn |
| `0C22A104` | `0C1F8B20` (AddScore) | `A03F0480` | item collect calls a wrapper: for gold (item kind 0–2) AddHit(1), then item+0x50 = medal × HIT ÷ 10, then AddScore; other items AddScore unchanged |
| `0C1F0F0C` | `0C1FD750` | `A03F04E0` | scene change (game start, next stage): wrapper clears the HIT count (`0CB363F8`) first |
| `0C27C724` | `1B55` mov.l r5,@(20,r11) | `0009` | HIT not cleared when the timer ends (it is cleared at each new stage instead) |
| `0C27B666` | `1205` mov.l r0,@(20,r2) | `0009` | HIT not cleared (second timer path) |
| `0C217D9C` | `0640` (1600) | `0000` | leaving spirit form early costs 0 energy (SubEnergy amount at `0C217D24`) |
| `0C238908` | `0C1FC140` (rank add) | `A03F0180` | enemy kill routine (`0C2385F0`): wrapper calls the rank add as before, then sets the revenge flag [r14+36] = 1 and count [r14+40] = 2 × lives, as the spirit branch does, so the normal branch fires revenge bullets too |
| `0C226F14` | `0C228960` (per-kind setup) | `A03F0400` | SpawnItem: a kind 0 (100) medal spawned within 50 px of the P1 hitbox becomes kind 1 (1,000) |
| `0C22994E` | `890F` bt 0x0C229970 | `0009` | spirit branch: energy (item+0xB0 == 4) is no longer forced to release (state 4) |
| `0C227F50` | `0C228A60` (item main) | `A03F0280` | energy items run through a wrapper: item+0xA4 = 1 in spirit form (orbit the player, like gold; skips the other forced release at `0C229948`), 0 in ship form; lifetime item+0xB4 paused in spirit form |
| `0C1FF3D2`–`0C1FF3DE` | slow-% countdown (`90B1 018E 2118 8D03 6B83 71FF 0816`) | `D102 410B 0009 A002 0009` + literal `A03F0200` | bullet manager calls our orb routine: slow = 50 inside 24 px of the P1 orb, back to 0 when it leaves; any other slow value counts down as before |

The target-player check matters. Sending items to release before they have picked a player trips the game's own `lpBui->m_SerchPlayer != -1` check (bui/buisub.cpp) and stops the game, which an earlier version of this patch did.

## Build from source

Requires `binutils-sh-elf` (`sh-elf-as`, `sh-elf-objcopy`) and Python 3.

```
make U4=/path/to/original/u4                              # -> build/u4 (CRC32 eb8366f2)
python3 tools/web/diff.py /path/to/original/u4 build/u4 > patch.json
python3 tools/web/gen.py patch.json                       # regenerates index.html and mister/*.mra
```

## Testing

Tested in MAME 0.289 (headless) with the patched u4, booted from power-on:

- **Boot:** the boot, memory check and title are normal.
- **Spirit form, stage 1 with Tsubaki:** gold flies straight in, and HIT goes up with each piece collected (12 → 31 → 44) without being reset when its timer runs out.
- **10,000-frame run:** repeated spirit form, through the stage 1 boss into stage 2. No game error, and HIT carried over the stage change (194 → 402 → 430).

## Notes

`docs/akatana-mechanics.md` covers the mechanics research: the player structure, rank, gold ageing and payout, the HIT counter and the 256-item limit.

Not affiliated with or endorsed by Cave or exA-Arcadia.
