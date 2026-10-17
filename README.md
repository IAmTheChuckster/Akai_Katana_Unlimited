# Akai Katana Gold

A gameplay patch for Akai Katana (Cave, CV1000-D, 2010/8/13 MASTER VER., u4 CRC `613fd380`).
This repository holds only source and notes. **No ROM data is included**; you build the patched u4 from your own dump.

## What it changes

- **Gold is collected automatically.** In spirit (念身) form, gold no longer orbits the hitbox until the form ends. Each piece goes straight to the release state and is collected at once.
- **HIT counts collected gold.** The +1 HIT now happens when a gold piece is collected, not when it spawns.
- **HIT is never reset.** The two places that clear the count when its 3-second display timer runs out are disabled.

Side effect: because gold no longer ages while orbiting, every piece is worth 100 points. In the original game it grows to 1,000 and then 10,000. Gold from a defeated boss still starts at 10,000.

## How it works

The main program is stored compressed in u4 and unpacked into RAM at boot, so the code can't be edited in the ROM directly. Instead:

1. The boot code's call to `0x0C1DE164` (literal at u4 `0x1D4`) is pointed at a hook in u4's free space (`0x3F0000`, CPU `0xA03F0000`).
2. The hook writes the patches into RAM (through P2 uncached addresses), then continues to `0x0C1DE164`.

| RAM address | Original | New | Effect |
|---|---|---|---|
| `0C22989C` | `E402` mov #2,r4 | `E404` mov #4,r4 | gold enters release (4) instead of orbit (2) |
| `0C226F34` | `4A0B` jsr @r10 (AddHit) | `0009` nop | no HIT on spawn |
| `0C27C724` | `1B55` mov.l r5,@(20,r11) | `0009` | HIT not cleared when the timer ends |
| `0C27B666` | `1205` mov.l r0,@(20,r2) | `0009` | HIT not cleared (second timer path) |
| `0C22A104` | `0C1F8B20` (AddScore) | `A03F0100` | item collect calls a wrapper: AddScore, then AddHit(1) if the item kind (item+0x34) is 0–2 (gold) |

## Build

Requires `binutils-sh-elf` (`sh-elf-as`, `sh-elf-objcopy`) and Python 3.

```
make U4=/path/to/original/u4
```

This produces `build/u4`. Put it in a copy of the set with the original u2, u23 and u24. MAME will report a wrong checksum for the patched u4; that is expected.

## Status

- The RAM changes were tested in MAME 0.289 on stage 1 with Tsubaki: gold was collected immediately during spirit form.
- **The built u4 (boot hook + collect wrapper) has not been boot-tested yet.**

## Notes

`docs/akatana-mechanics.md` covers the mechanics research: the player structure, rank, gold ageing and payout, the HIT counter and the 256-item limit.
