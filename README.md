# Akai Katana Gold

A gameplay patch for Akai Katana (Cave, CV1000-D, 2010/ 8/13 MASTER VER., u4 CRC32 `613fd380`).
This repository holds only source, tools and notes. **No ROM data is included**; you patch your own dump.

## Patch it in your browser

Open the web patcher (`index.html`, served by GitHub Pages) and drop your `akatana.zip`. It:

- checks the CRC32 of `u4`, `u2`, `u23` and `u24`;
- builds the patched `u4` (CRC32 `d899ec64`);
- gives you `akatanagold.zip` (the full set with `u4` replaced), `u4.zip` and the raw `u4`;
- builds `Akai Katana Gold.mra` for MiSTer (ikacore CV1k), filled in with the CRC32s of the files it found, including the new `u4`.

Everything runs locally in the browser; nothing is uploaded. A ready-made `.mra` with the standard CRC32s is in `mister/`.

## What it changes

In spirit form (念身):

- **Gold is collected automatically.** Gold no longer circles the ship until spirit form ends. As soon as a piece has a player to fly to, it goes to the release state and is collected.
- **HIT counts collected gold.** The +1 HIT now happens when a gold piece is collected, not when it spawns.
- **HIT never resets.** Both places that clear the count when its 3-second display timer runs out are disabled. The count carries on for the whole game, across stages. The number is still only shown while it is counting up.

Side effect: gold no longer ages while orbiting, so normal gold is worth 100 points per piece (it used to grow to 1,000 and 10,000). Gold from a defeated boss still starts at 10,000.

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
| `0C22A104` | `0C1F8B20` (AddScore) | `A03F0100` | item collect calls a wrapper: AddScore, then AddHit(1) if the item kind (item+0x34) is 0–2 (gold) |
| `0C27C724` | `1B55` mov.l r5,@(20,r11) | `0009` | HIT not cleared when the timer ends |
| `0C27B666` | `1205` mov.l r0,@(20,r2) | `0009` | HIT not cleared (second timer path) |

The target-player check matters. Sending items to release before they have picked a player trips the game's own `lpBui->m_SerchPlayer != -1` check (bui/buisub.cpp) and stops the game, which an earlier version of this patch did.

## Build from source

Requires `binutils-sh-elf` (`sh-elf-as`, `sh-elf-objcopy`) and Python 3.

```
make U4=/path/to/original/u4                              # -> build/u4 (CRC32 d899ec64)
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
