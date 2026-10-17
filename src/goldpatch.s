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
L_wcnt: .long   4
L_ltbl: .long   0xA03F00C0
L_lcnt: .long   1
L_orig: .long   0x0C1DE164

! ---- word patches (address, value)
        .org 0x80
        .long 0xAC22989C, 0xE404   ! gold: enter release state (4) instead of orbit (2) -> collected at once
        .long 0xAC226F34, 0x0009   ! spawn: no HIT +1 when gold spawns (was jsr AddHit)
        .long 0xAC27C724, 0x0009   ! HIT: do not clear count when display timer ends
        .long 0xAC27B666, 0x0009   ! HIT: do not clear count (second timer path)
! ---- long patches
        .org 0xC0
        .long 0xAC22A104, 0xA03F0100   ! item collect: AddScore -> our wrapper

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
