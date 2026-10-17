! Akai Katana gold patch: boot hook + gold-collect wrapper (u4 offset 0x3F0000, CPU 0xA03F0000)
        .text
        .org 0
! ---- boot hook: called instead of 0x0C1DE164 (after the program is unpacked into RAM)
hook:
        mov.l   L_wtbl,r1
        mov.l   L_wcnt,r3
1:      mov.l   @r1+,r2          ! address (P2, uncached)
        mov.l   @r1+,r4          ! 16-bit value
        dt      r3
        bf/s    1b
        mov.w   r4,@r2
        mov.l   L_ltbl,r1
        mov.l   L_lcnt,r3
2:      mov.l   @r1+,r2
        mov.l   @r1+,r4
        dt      r3
        bf/s    2b
        mov.l   r4,@r2
        mov.l   L_orig,r0        ! continue with the original call (pr still returns to boot)
        jmp     @r0
        nop
        .align 2
L_wtbl: .long   0xA03F0080
L_wcnt: .long   7
L_ltbl: .long   0xA03F00C0
L_lcnt: .long   5
L_orig: .long   0x0C1DE164

! ---- word patches (address, value)
        .org 0x80
        .long 0xAC22989C, 0x6423   ! orbit entry: mov r2,r4  (state chosen by our routine: 4 = release, 2 = orbit)
        .long 0xAC2298A0, 0x6623   ! orbit entry: mov r2,r6  (dispatch the same state this frame)
        .long 0xAC226F34, 0x0009   ! spawn: no HIT +1 when gold spawns (was jsr AddHit)
        .long 0xAC27C724, 0x0009   ! HIT: do not clear count when display timer ends
        .long 0xAC27B666, 0x0009   ! HIT: do not clear count (second timer path)
        .long 0xAC217D9C, 0x0000   ! spirit form: leaving early costs 0 energy (was 0x0640 = 1600)
        .long 0xAC2388D2, 0x0009   ! enemy kill, spirit branch: keep our revenge count (was mov.l r12,@(40,r14))
! ---- long patches
        .org 0xC0
        .long 0xAC22A104, 0xA03F0100   ! item collect: AddScore -> our wrapper
        .long 0xAC2299D8, 0xA03F0140   ! orbit entry: random() call -> our state chooser
        .long 0xAC238908, 0xA03F0180   ! enemy kill: rank-add call -> wrapper that also arms revenge bullets
        .long 0xAC1FFFDC, 0xA03F01C0   ! cancelled bullet -> gold (bullet in r8): SpawnItem -> wrapper (revenge -> 10,000 gold)
        .long 0xAC20084C, 0xA03F01E0   ! cancelled bullet -> gold (bullet in r12): SpawnItem -> wrapper (revenge -> 10,000 gold)

! ---- collect wrapper: AddScore(r4,r5,r6); if item kind (r9+0x34) <= 2 (gold) -> AddHit(1)
        .org 0x100
wrap:
        sts.l   pr,@-r15
        mov.l   r8,@-r15
        mov.l   @(52,r9),r8      ! item kind
        mov.l   L_addscore,r0
        jsr     @r0
        nop
        mov     #2,r1
        cmp/hi  r1,r8            ! kind > 2 -> not gold
        bt      3f
        mov.l   L_addhit,r0
        jsr     @r0
        mov     #1,r4
3:      mov.l   @r15+,r8
        lds.l   @r15+,pr
        rts
        nop
        .align 2
L_addscore: .long 0x0C1F8B20
L_addhit:   .long 0x0C27B500

! ---- orbit-entry state chooser (called instead of random(r4) at 0x0C229896; r13 = item)
! returns r0 = random(r4) as before, and r2 = new state:
!   4 (release -> flies to the player and is collected) for gold (kind 0-2) that already has
!     a target player (item+0x110 >= 0), copying the target to item+0x114 like the game's own
!     release code does;
!   2 (orbit, unchanged behaviour) for everything else.
        .org 0x140
choose:
        sts.l   pr,@-r15
        mov.l   L_rand,r1
        jsr     @r1
        nop
        mov     #2,r2
        mov.l   @(52,r13),r1     ! item kind
        mov     #2,r3
        cmp/hi  r3,r1
        bt      4f               ! not gold
        mov.w   L_o110,r3
        mov     r13,r1
        add     r3,r1            ! r1 = item+0x110 (target player)
        mov.l   @r1,r3
        cmp/pz  r3
        bf      4f               ! no target player yet -> orbit as normal
        mov.l   r3,@(4,r1)       ! item+0x114 = target
        mov     #4,r2
4:      lds.l   @r15+,pr
        rts
        nop
L_o110: .word   0x110
        .align 2
L_rand: .long   0x0C1E4190

! ---- enemy kill: revenge bullets in every mode (called instead of the rank-add routine 0x0C1FC140)
! The kill routine (0x0C2385F0) only fires revenge bullets when its frame flag [r14+36] is set and
! uses [r14+40] (2 x lives) as the count; originally only the spirit-form branch sets them.
! Both branches call the rank-add routine through one pointer (0x0C238908), so we call it as before
! and then arm the revenge bullets the way the spirit branch does, at 5x the normal count
! (the spirit branch's own store of 2 x lives at 0x0C2388D2 is nopped so ours is kept). r8 = player life (0x640 per life)
! in both branches at this point; r14 is the kill routine's frame.
        .org 0x180
revenge:
        sts.l   pr,@-r15
        mov.l   L_rankadd,r0
        jsr     @r0
        nop
        mov     r8,r1            ! life
        mov.w   L_1600,r2
        mov     #0,r3
5:      cmp/ge  r2,r1            ! lives = life / 1600
        bf      6f
        sub     r2,r1
        bra     5b
        add     #1,r3
6:      mov     r3,r1
        shll2   r3
        add     r1,r3            ! 5 x lives
        add     r3,r3            ! 10 x lives = 5 x the game's own count (2 x lives)
        mov.l   r3,@(40,r14)
        mov     #1,r1
        mov.l   r1,@(36,r14)     ! fire revenge bullets
        lds.l   @r15+,pr
        rts
        nop
L_1600: .word   1600
        .align 2
L_rankadd: .long 0x0C1FC140

! ---- cancelled bullet -> gold. In spirit form, bullets close to a destroyed enemy are cancelled
! (bullet state 9) and each one drops 100 gold through SpawnItem, from 0x0C1FFFA6 (bullet in r8) or
! 0x0C200830 (bullet in r12); these wrappers replace SpawnItem for those call sites (r4 = item kind). Gold (kind 0-2) from a revenge bullet (type 0x4A at bullet+0x0C)
! becomes kind 2 = 10,000 gold. Everything else is passed through unchanged.
        .org 0x1C0
cgold:
        mov     #3,r1
        cmp/hs  r1,r4            ! kind >= 3 (unsigned) -> not gold
        bt      7f
        mov.l   @(12,r8),r0      ! bullet type
        cmp/eq  #0x4A,r0
        bf      7f
        mov     #2,r4            ! 10,000 gold
7:      mov.l   L_spawn,r0
        jmp     @r0
        nop
        .align 2
L_spawn: .long 0x0C226DC0

        .org 0x1E0
cgold12:
        mov     #3,r1
        cmp/hs  r1,r4
        bt      8f
        mov.l   @(12,r12),r0     ! bullet type
        cmp/eq  #0x4A,r0
        bf      8f
        mov     #2,r4
8:      mov.l   L_spawn2,r0
        jmp     @r0
        nop
        .align 2
L_spawn2: .long 0x0C226DC0
