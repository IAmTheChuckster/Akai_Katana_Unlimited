# Akai Katana (CV1000-D): mechanics notes

Studied headless in MAME 0.289 with the unpatched set. No ROM data is included in these notes.

## Set and emulator

- **Set:** `akatana`, Akai Katana (Japan, 2010/ 8/13 MASTER VER.), Cave CA021.
  - u4 CRC 613fd380, u2 89a2e1a5, u23 34a67e24, u24 10760fed. `-verifyroms` reports the set as good.
- **Board:** CV1000-D, `cv1k_d` machine. The u4 is 4 MB; RAM is 16 MB at 0x0C000000–0x0CFFFFFF. The screen is 320×240 at ROT0, so the game scrolls horizontally.
- **Emulator:** MAME 0.289 has the game switched off. It was removed on 31/12/2021 at the request of the rights holder, exA-Arcadia. The source still has the ROM definition under `#if 0`, with the GAME line commented out.
  - We rebuilt 0.289 locally with only `akatana` turned back on. That took three changes: the cv1k.cpp `#if 0`, the GAME line, and an entry in `mame.lst`.
  - The patch is `patches/akatana_enable_0289_local.patch`. The binary is `bin/cv1k_ak`, which prints version `0.289 (mame0289-dirty)`. It is for private use only; do not distribute it.
- **Boot:** the first boot initialises the EEPROM. After that, the boot shows the memory check, EEPROM check, warning, ranking, Cave logo, then the title at about frame 3600. A good dump gives no checksum warning.
- **Speed:** about 50–75 fps headless with `-nodrc`. Busy boss fights run slower.

## Getting into a game (`BT_SCHED`/harness tokens)

1. `10 K` / `16 -` inserts a coin.
2. `60 S` / `66 -` presses 1P start.
3. Pilot select appears at about frame 170 and is cursor based. Press `R` at frame 200 or later to move the cursor (presses before 180 are ignored), then `A` at 280. The cursor wraps through 椿 Tsubaki → 牡丹 Botan → 紫苑 Shion.
4. Control-layout select appears at about frame 470. Press `A` at 600.
5. The intro cut plays, and you have control at about frame 920.

Each select screen has a 10-count timer and picks the current option by default.

**Test mode:** we could not enter it. We tried the S3 button (PORT_F 0x02), the JAMMA test input (PORT_C 0x02), holding the button from power-on, and holding it at the title. Still to investigate.

According to the program strings, test mode contains:
- **Game configuration:** DIFFICULTY 1–4 (EASY, NORMAL, HARD, VERYHARD; default RANK2 NORMAL), EXTEND SETTING, and LIFE COUNTS.
  - Extend choices: 20M/50M (default), 30M/60M, 30M every, 50M only, or none.
- **System configuration:** coin mode, continue, demo sound, rank display, and chute type.
- **Back-up data:** rankings per TYPE-A/B/C, each with sub-entries 1 and 2.

## Controls

The control-select screen offers two layouts. Translated from the Japanese:

| Button | Layout A (default) | Layout B |
|---|---|---|
| 1 (A) | Shot (ショット) | Shot |
| 2 (B) | Bomb (ボム) | Bomb |
| 3 (C) | Auto-fire (オート連射) | Spirit form (念身) |
| 4 (Q) | Spirit form (念身) | Auto-fire |

Behaviour was measured from per-frame RAM dumps. Input takes effect one frame later.

- **Tap A:** normal shot.
- **Hold A:** attack mode. The familiar orb fires a laser or stream in front of the ship, and the ship slows down. Slowdown starts after about 10 frames (14 for Botan) and drops 0.1875 px/frame every 2 frames to a floor.
- **Hold C (auto-fire):** rapid shot at full speed. No slowdown.
- **B:** bomb. A big red crest explosion that clears the screen. Uses one bomb.
  - Being hit with bombs in stock fires an **auto-bomb that uses all of them** (3 → 0). We saw this at frame 1000 of the idle test, and no life was lost.
- **Q (念身, spirit form):** turns the player into a spirit orb, and the portrait switches to the partner pilot.
  - It works with any energy above 0; we tested down to 0x100. It drains energy by about 4–5 per frame until energy is empty, even after Q is released.
  - During spirit form a HIT counter runs, and enemies destroyed drop gold medals that circle the player (see Gold medal payout).
  - When it ends, the medals are collected and pay out as score popups. In our test this took the score from 9,350 to 183,740 within about 80 frames.
  - Rank rises sharply while spirit form is active (see Rank).

### Movement speed

Speeds are in px/frame, in 16.16 fixed point.

| Pilot | Normal / C held | A held (floor) |
|---|---|---|
| Tsubaki | 3.25 | 1.5 |
| Botan | 3.625 | 1.75 |
| Shion | 2.375 | 2.0 |

### Shots seen

- **Tsubaki:** narrow, strong forward streams. Holding A gives a wide fan laser.
- **Botan:** forward shot plus side fire streams. Holding A sends the orb's fire streams forward.
- **Shion:** wide missile spread. Holding A gives an orb with a spread.

## Player data (P1)

The player-control object has handle type 0x81, and its base is 0x0C7E8628. The program also contains source paths such as `gamecontrol/playercontrol.cpp`; the accessor functions for this object are at 0x0C1F7500–0x0C1FC550.

The ship's position and velocity are a separate block that starts at 0x0C7E86F4. Every field below was confirmed by watching it change in play and, where noted, by poking it.

| Address | Size | Meaning |
|---|---|---|
| 0C7E8630 | l | **Life**, in units of 0x640 per life. Starts at 0x12C0 = 3 lives. −0x640 per death; +0x640 per extend. |
| 0C7E8634 | l | Life cap. Moves with life on death and on extends; maximum 0x1F40 (5 lives). |
| 0C7E863C | l | **Energy gauge**, the green part of the bar. Starts at 0x640. Raised by energy items and on death; drained by spirit form. |
| 0C7E8644 | l | 0x1F40: bar maximum. |
| 0C7E8650 | b | **Bombs**, starting at 3. 0C7E8651 = 3 (probably the maximum). |
| 0C7E8663 | b | Spirit form active: 3 = on, 0 = off. |
| 0C7E8690 | l | Counter that rises with kills, resets on death and reaches 64 in spirit form; feeds into rank. Not the on-screen HIT number (that is 0CB363F8). |
| 0C7E86AC | 12 bytes | **Score as decimal digits, one per byte, least significant first.** 86AC holds the ones digit. |
| 0C7E86D8 | l | Number of times hit (deaths plus auto-bombs). |
| 0C7E86F4 / F8 | l, l | Respawn position (50, 120). |
| 0C7E86FC / 8700 | l, l | **X / Y position (the hitbox: centre of the ship/character), 16.16 fixed point.** Y counts upward from the bottom: screen y ≈ 240 − Y, and Y is at most 234. Poking X moves the ship. |
| 0C7E8704 / 8708 | l, l | Velocity X / Y, 16.16. |
| 0C7E87C8 | l | **Invulnerability timer.** 43 at stage start, 250 after a respawn, counts down each frame. Holding it at 0x3C makes the player invulnerable (tested over 1,500 idle frames). |

The life value 0C7E8630 has three writers:
- 0C1F8EA0: subtract (line 2737).
- 0C1F90E0: transfer from +4 into +8, capped at +12 (line 2829).
- 0C1F9200: lower the cap (line 2878).

The bomb counter's writers are 0C1F9F80 (use) and 0C1FC4AA (set; called from 0C1F7E82).

## Game-manager variables

| Address | Meaning |
|---|---|
| 0C7E669C, 0C7E674C, 0C7E6750 | **Stage index**, 0-based. Checked at stages 1–5. |
| 0C7E664C | In-game frame counter. |
| 0C7E6658 | **Rank**, 0–255. |
| 0C7EB3C0 / C4 | Rank, per-player part (P1 / P2). |
| 0C7EB3C8 / CC | Rank, life part (P1 / P2). |
| 0C7EB3D0 | Rank, maximum of the life parts. |
| 0C7EB3D8 | Rank, flag set while spirit form is active. |

## Scoring and extends

- **Normal kills:** about 240 points for a small helicopter in stage 1.
- **Energy items:** enemies drop green "E" items.
- **Spirit form:** builds a HIT chain, and kills drop gold medals whose value grows the longer they are held. They pay out when the form ends. **This is the main scoring engine;** see Gold medal payout.
- **Extends** (default setting) at **20,000,000 and 50,000,000**, each worth +0x640 life and cap. We verified this by poking the score to 19,999,000 and 49,999,000: the extend arrives on the next score change.
- **Score reached in our autoplay** (lives held, no deliberate spirit-form use): 1.17M at the start of stage 2, 7.7M at stage 3, 12.6M at stage 4, and 19.9M in stage 5.

## Gold medal payout (spirit form)

Traced with breakpoints on the score routines and checked against a run: the payout in the test was 14 × 10,000 + 32 × 1,000 + 16 × 100 = 173,600 points, exactly the score gained.

1. **Where medals come from.** While spirit form is active, medals appear when enemies are destroyed (2 for a small enemy, 9 for a bigger one) and when enemy bullets reach the spirit orb (the stage 2 boss ring gave 40 at once). Outside spirit form none appear. The item manager runs each medal's init (0C227840) from its per-frame loop at 0C226CB4.
2. **Every medal starts at tier 0, worth 100.** The medals circle the ship.
3. **Medals age.** Each medal counts frames (medal +0x90; its tier is at +0x8C). It moves up a tier when the count passes a threshold from the table at 0C4D88E4:
   - tier 0 (100 pts) → tier 1 (1,000 pts) after 60 frames;
   - tier 1 → tier 2 (10,000 pts) after another 100 frames;
   - tier 2 is the top.
   A medal held about 2.7 seconds is therefore worth 100 times more than a new one. Ageing pauses while a game-manager flag (manager +0xA0, read by 0C1F60E0) is set.
4. **Values come from a table**, not code constants. Rows of 7 longwords at 0C4D8924 (RAM): `96, 48, 0, 100, 1000, 10000, 32768`. A second row holds `100, 500, 2000` for a medal type not yet identified, and a third repeats 100/1000/10000. The update at 0C228CA2 copies the value for the current tier into medal +0x50.
   **Bullets do not make a medal grow.** We tested this with spirit form during the stage 2 boss (state `auto_24000`, 40 medals) and watched every write to medal tier and age. Only the timer code (0C2291DA–0C2291F6, reset at 0C229260) and the init routines wrote them. Every medal took exactly 61 frames to reach 1,000 and another 101 frames to reach 10,000.
   - What does grow when bullets meet the spirit orb is the **number** of medals: bullets near the orb are turned into new 100-point medals.
   - Each tier-up also plays a "pop" scale animation: a counter at medal +0xC0 runs 58 → 0 in steps of 6.
   **Gold that starts at 1,000 or 10,000.** Items are spawned by SpawnItem (0C226DC0) with a kind number; kind 0/1/2 = gold worth 100/1,000/10,000, through the init table at 0C4D89B0. Bullets are converted by CancelBullets(kind, owner) at 0C1FED50, which puts the kind into every bullet; each bullet then becomes that item (0C1FFF30).
   - **Boss defeated → every bullet on screen becomes 10,000 gold at once (kind 2).** Every main boss (`st1boss`–`st6boss`) calls CancelBullets with a hard-coded 2. Seen in play: stage 1 boss gave 23 pieces at frame 1985 of `auto_6000`, outside spirit form; stage 2 boss gave 2. Each paid 10,000.
   - **Boss part or phase breaks** cancel with kind 0 (100) or −1 (no gold). **Mid-bosses** (`st1mboss`–`st5mboss`) cancel with kind 0.
   - **Kind 1 (1,000 from the start)** has an init routine (0C2278D0) but no caller we found uses it. Enemy drops (0C213584) take their kind from enemy data and were always 0 in our runs.

   **HIT counter and the 256 limit.** The HIT number is in a display object at 0CB363E4: +0x14 (0CB363F8) is the count and +0x18 is a 180-frame display timer.
   - Every gold piece spawned adds 1 HIT: SpawnItem calls AddHit(1) at 0C27B500 for the gold kinds. The count itself has no cap.
   - SpawnItem refuses to create any pickup item (kinds 0–14, gold included) while 256 or more items are alive. This is the check at 0C226E1C–0C226E26, against the literal 0x00FF at 0C226EE8. Other kinds are limited to 2,000 (0x07CF at 0C226EE6). The live item count is at item manager +0xA7F94 (0CAEE824 in our runs).
   - Gold stays alive while spirit form lasts, so once 256 pieces are out, no more gold spawns and HIT stops at 256. Bullets and kills beyond that give nothing.
   - Verified: with the live count pre-set to 250 or 240, the stage 2 boss bullet ring produced only 6 or 16 gold pieces (HIT 6 / 16) instead of 40, and the count stopped at 256.

   **Gold orbits the hitbox** (our name for the centre of the ship/character: the player position at 0C7E86FC/0C7E8700). Measured on 40 medals over 320 frames during the stage 2 boss: measured from the ship, the medals' distances spread by only 3.5 px around a radius of about 72 px. Measured from the point 18 px ahead of the ship, they spread by 10 px. The gold circles clockwise, about 140 frames per lap, starting at a radius of about 35 px and widening to about 72 px. Item positions are at +0x54/+0x58 (16.16, Y up).
   - **The orb** (the point ahead of the ship; the energy items orbit it, per player knowledge, not yet measured here): each frame the item manager also stores a point per player in a 32-byte slot at 0CA46848 (P1): +0 player handle, +4/+8 ship X/Y, +0xC/+0x10 a point 18 px in front of the ship (24 px while Shot is held), at 0CA46854/0CA46858. The values are set by 0C1F8610 and 0C21D0B0 from the per-frame loop at 0C226C50, and the slot is only filled while items exist. The gold does not orbit it; the gold orbits the hitbox.
   - Item kinds 15 and 16 also appear in spirit form, shared state routine 0C229A40. They gather briefly near the orb and at the far end of the attack laser. We have not yet confirmed which of them are the energy items.

5. **Payout.** When spirit form ends, the medals fly to the player and are collected over about 60–80 frames. Each one adds its current value through AddScore (0C1F8B20, called from 0C22A0DA) and shows a popup (0C22A320).
   - There is **no HIT-count multiplier**: the HIT counter does not change the medal values.
6. **Medal lifetime.** At tier 2 a countdown (medal +0xB4) runs; below 500 the medal changes state (6) and starts fading.

How score is added in general: callers pass points to AddScore (0C1F8B20, handle in r4, points in r5). This accumulates into a pending total at 0C7E86A4, capped at 999,999,999. Once per frame, 0C1F7F20 adds the pending total into the score digits through 0C1E5D40, which works on 32 decimal-digit buffers.

| Score source seen in the test | Caller (PR) | Values |
|---|---|---|
| Enemy destroyed | 0C20940E | 100–280 in stage 1 |
| Gold medal collected | 0C22A0DE | 100 / 1,000 / 10,000 |
| Hits while in spirit form / with the laser | 0C219B8E, 0C21A53A, 0C21D8E4 | 10 each |

## Rank (`gamecontrol/diffic.cpp`, update at 0C1FCA40)

This was read from the disassembly and checks out against the data.

1. Each frame, a callback (0C1FCB50) for each player computes a per-player part in 0C7EB3C0:
   - bombs × 4, plus a per-state term;
   - plus a larger term while spirit form is active, which also sets 0C7EB3D8.
2. The life part is lives × 24, stored in 0C7EB3C8.
3. Rank = per-player part + (frame counter >> 9), which is +1 every 512 frames. Then the difficulty base from the table at 0C32A344 is added (32, 48, 64, 80, 96, 112).
4. The result is clamped to a cap:
   - normal: 0x70 + lives × 24 (0xB8 with 3 lives);
   - in spirit form: 0xB0 + lives × 24;
   - never above 0xFF.

What this looks like in play:
- Rank was 0x1D at the start of stage 1, 0x25 later in stage 1, 0x32 in stage 2, 0x3D in stage 3 and 0x46 in stage 4.
- It drops after a death and after bombing.
- One spirit-form use took it from 0x21 to 0x8D, and it fell back to 0x1D afterwards.

A second table at 0C32A224 has 72 entries. It is used when a flag at object +0x148 is set; that path is not decoded yet.

## Stages and BGM

- **Stages:** there are 6 stages, according to the `st1boss`–`st6boss` and `st1mboss`–`st5mboss` source paths. In the autoplay, stage 2 began about 8,300 frames after stage 1 started, stage 3 about 28,200, stage 4 about 48,400 and stage 5 about 79,300. Stage 6 was not reached in about 116,000 frames.
- **Sound:** the YMZ770 sequence starts were logged as register 0x80 = sequence number, then 0x81 = 02.

| Sequence | When it starts |
|---|---|
| 0x00 | Credit / start pressed |
| 0x01 | Pilot select |
| 0x02 | Stage 1 intro cut |
| 0x03 | Stage 1 BGM |
| 0x06 | Boss warning (about 87 frames before 0x07) |
| 0x07 | Boss theme; restarts with each boss form |
| 0x08 | Stage clear, at the stage change |
| 0x09 | About 200 frames later (next-stage intro) |
| 0x04 | Stage 2 BGM |
| 0x0C | Stage 3 BGM (0x0D starts about 950 frames in) |
| 0x0E | Stage 4 BGM (0x0F starts about 3,850 frames in) |

- **Not logged yet:** stage 5 and 6 BGM, sequences 0x05, 0x0A and 0x0B, and how the boss theme differs between stages.

## Program and code

- **Location:** the program runs from RAM after the boot copy (the code area is 0x00C17EB0 bytes). The idle loop is at PC 0C1D1346.
- **Source paths:** the binary still contains them, for example `gamecontrol/playercontrol.cpp`, `fighter/shot/type_a/fshot_a.cpp`, `bomb/bomb.cpp`, `ichiene/stgN/*.cpp` and `stNboss/*`. The string table is at about 0C303000–0C315000.
- **Handle lookup:** 0C1ED370(handle, type, file, line) returns `0x0C000000 | (handle & 0xFFFFFF)`. The high byte of a handle is its type.

## Save states and tools

All of these are on this machine under `~/cv1k/cv1k_testenv/work/sta/akatana`. They are MAME 0.289 local build only.

**Save states**

| State | What it is |
|---|---|
| `title` | Title screen |
| `s1_tsubaki`, `s1_botan`, `s1_shion` | Stage 1, player in control, layout A |
| `auto_6000` … `auto_66000`, `autoB_*` | Tsubaki autoplay every 6,000 frames, stages 1–5 (lives held) |

**Tools**

- `lua/akatana_harness.lua` with `scripts/ak.sh`, controlled by these settings:
  - schedule: `AK_SCHED`, with a rapid-tap `*N` option;
  - output: `AK_DUMP`, `AK_RAMAT`, `AK_SNAP`/`AK_SNAPEVERY`;
  - saves: `AK_SAVES`;
  - memory: `AK_HOLD`, `AK_POKE`;
  - write taps: `AK_TAPW`;
  - debugger: `AK_DBG`, which writes `T <t> <frame>` to `error.log`.
- `work/ymzrun.sh state frames` logs YMZ770 writes with a debugger watchpoint. A Lua write tap does not work here, because the high byte lane is too large for a Lua integer.

## Open questions

- How to enter test mode in MAME, and where the DIFFICULTY, EXTEND and LIFE settings are stored in EEPROM and RAM.
- The full per-state rank term, and when the 0C32A224 table applies.
- What the second medal value row (100/500/2000) is used for, and what the game-manager flag that pauses medal ageing is.
- How energy items are valued, and whether HIT/energy behave differently per pilot.
- Stage 5 and 6 BGM numbers, the second loop (if any), and the TYPE-A/B/C "1/2" ranking split.
