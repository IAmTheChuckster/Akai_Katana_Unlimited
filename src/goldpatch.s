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
L_wtbl: .long   0xA03F0300
L_wcnt: .long   12
L_ltbl: .long   0xA03F0600
L_lcnt: .long   6
L_orig: .long   0x0C1DE164

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

! ---- orb slow-down. Replaces the bullet manager's per-bullet step at 0x0C1FF3D2 that counts down the
! bullet's slow percentage (bullet+0x138; the move code at 0x0C2010F0 moves a bullet by
! velocity x (100 - slow) / 100). r8 = bullet. Enemy bullets within ORB_R px of the P1 orb
! (0x0CA3FBB4/0x0CA3FBB8, 16.16, the familiar's live position for every character, in ship and
! spirit form) get slow = 50 (half speed). A bullet that leaves the radius goes straight back to
! 0 (full speed); any other slow value the game set is counted down as before.
! Must keep r4 (and r8); r0/r1 are free here (the original code reloads them).
        .equ ORB_R, 24
        .org 0x200
orbslow:
        mov.l   r2,@-r15
        mov.l   r3,@-r15
        mov.l   r5,@-r15
        mov.l   r6,@-r15
        mov.w   L_o138,r0
        mov.l   @(r0,r8),r1      ! current slow %
        mov.l   L_orb,r3
        mov.l   @(48,r8),r5      ! bullet x
        mov.l   @r3,r2           ! orb x
        sub     r2,r5
        shlr16  r5
        exts.w  r5,r5            ! dx in px
        mov.l   @(52,r8),r6      ! bullet y
        mov.l   @(4,r3),r2       ! orb y
        sub     r2,r6
        shlr16  r6
        exts.w  r6,r6            ! dy in px
        mul.l   r5,r5
        sts     macl,r5
        mul.l   r6,r6
        sts     macl,r6
        add     r6,r5            ! dx^2 + dy^2
        mov.w   L_r2,r2
        cmp/hs  r2,r5
        bt      10f              ! outside the radius
        mov     #50,r2           ! inside: half speed
        bra     12f
        mov.l   r2,@(r0,r8)
10:     tst     r1,r1
        bt      12f              ! already full speed
        mov     #50,r2
        cmp/eq  r2,r1
        bf      11f
        mov     #1,r1            ! ours (50): back to full speed now
11:     add     #-1,r1           ! game's own value: count down as before
        mov.l   r1,@(r0,r8)
12:     mov.l   @r15+,r6
        mov.l   @r15+,r5
        mov.l   @r15+,r3
        rts
        mov.l   @r15+,r2
L_o138: .word   0x138
L_r2:   .word   ORB_R*ORB_R
        .align 2
L_orb:  .long   0x0CA3FBB4

! ---- energy balls orbit the player in spirit form. Energy items (kind 12) use the same item routine
! as gold (0x0C228A60). In spirit form the game sends every energy ball to be collected (state 4) at
! 0x0C229948 (item+0xA4 == 0) and 0x0C229978 (item+0xB0 == 4, the energy marker). We nop the second
! check, and run energy items through this wrapper, which each frame sets item+0xA4 = 1 while P1 is in
! spirit form (P1 player state 0x0C7E8660 = 3-5; the same states the item routine switches on) (the
! flag gold has while it orbits the player) and 0 otherwise (energy's normal value), so
! orbiting energy circles the hitbox like gold did, and when spirit form ends the balls that were orbiting the player are released and collected.
! Energy balls normally expire about 510 frames after they appear (lifetime item+0xB4 counts up, state 6
! past 500, 0x0C229210); the wrapper pauses that clock during spirit form so orbiting energy is never
! lost by going into spirit form. r4 = item.
        .org 0x280
emain:
        mov.l   L_pst,r1
        mov.l   @r1,r0           ! P1 player state (player+0x38, 0x0C7E8660): 3-5 = spirit form
        add     #-3,r0
        mov     #3,r1
        cmp/hs  r1,r0            ! T = not in spirit form
        mov.w   L_oA4,r1
        add     r4,r1            ! r1 = item+0xA4
        bt      20f
        mov     #1,r0
        mov.l   r0,@r1           ! spirit: orbit the player
        mov.w   L_oB4,r1
        add     r4,r1
        mov.l   @r1,r0           ! lifetime (counts up 1 per frame; fades past 500)
        cmp/pl  r0
        bf      21f
        add     #-1,r0           ! cancel this frame's tick: lifetime paused in spirit form
        bra     21f
        mov.l   r0,@r1
20:     mov.l   @r1,r0
        tst     r0,r0
        bt      21f              ! ship, and was not orbiting the player: orbit the orb as normal
        mov     #0,r0
        mov.l   r0,@r1           ! spirit form just ended: item+0xA4 = 0 ...
        mov.l   @(48,r4),r0
        cmp/eq  #2,r0
        bf      21f              ! (only balls still orbiting, state 2)
        mov.w   L_e110,r1
        add     r4,r1
        mov.l   @r1,r0           ! target player
        cmp/pz  r0
        bf      21f
        mov.l   r0,@(4,r1)       ! item+0x114 = target (as the game's own release does)
        mov     #4,r0
        mov.l   r0,@(48,r4)      ! ... and release it to the player: collected
21:     mov.l   L_imain,r1
        jmp     @r1
        nop
L_oA4:  .word   0xA4
L_oB4:  .word   0xB4
L_e110: .word   0x110
        .align 2
L_pst:  .long   0x0C7E8660
L_imain: .long  0x0C228A60

! ---- word patches (address, value)
        .org 0x300
        .long 0xAC22989C, 0x6423   ! orbit entry: mov r2,r4  (state chosen by our routine: 4 = release, 2 = orbit)
        .long 0xAC2298A0, 0x6623   ! orbit entry: mov r2,r6  (dispatch the same state this frame)
        .long 0xAC226F34, 0x0009   ! spawn: no HIT +1 when gold spawns (was jsr AddHit)
        .long 0xAC27C724, 0x0009   ! HIT: do not clear count when display timer ends
        .long 0xAC27B666, 0x0009   ! HIT: do not clear count (second timer path)
        .long 0xAC217D9C, 0x0000   ! spirit form: leaving early costs 0 energy (was 0x0640 = 1600)
        .long 0xAC1FF3D2, 0xD102   ! bullet manager: mov.l @(2,pc),r1  (r1 = orb-slow routine)   was mov.w 0x138,r0
        .long 0xAC1FF3D4, 0x410B   !   jsr @r1                                                     was mov.l @(r0,r8),r1
        .long 0xAC1FF3D6, 0x0009   !   nop                                                         was tst r1,r1
        .long 0xAC1FF3D8, 0xA002   !   bra 0x0C1FF3E0 (back to the original code)                  was bt/s
        .long 0xAC1FF3DA, 0x0009   !   nop                                                         was mov r8,r11
        .long 0xAC22994E, 0x0009   ! spirit form: energy (item+0xB0 == 4) no longer forced to release (was bt 0x0C229970)
! ---- close-range medals. SpawnItem (0x0C226DC0) stores the item kind (+0x34) and position
! (+0x54/+0x58, 16.16) and then calls the per-kind setup 0x0C228960 with r4 = kind; this wrapper
! replaces that call. A 100 medal (kind 0) that appears within NEAR_R px of the P1 hitbox
! (0x0C7E86FC/0x0C7E8700) becomes a 1,000 medal (kind 1). r6 = item; the caller reloads r6 and
! does not use r5/r7 afterwards.
        .equ NEAR_R, 50
        .org 0x400
near:
        tst     r4,r4
        bf      30f              ! only 100 medals
        mov     r6,r1
        add     #0x54,r1
        mov.l   @r1+,r2          ! medal x
        mov.l   @r1,r3           ! medal y
        mov.l   L_hb,r1
        mov.l   @r1+,r5          ! hitbox x
        mov.l   @r1,r7           ! hitbox y
        sub     r5,r2
        shlr16  r2
        exts.w  r2,r2            ! dx px
        sub     r7,r3
        shlr16  r3
        exts.w  r3,r3            ! dy px
        mul.l   r2,r2
        sts     macl,r2
        mul.l   r3,r3
        sts     macl,r3
        add     r3,r2
        mov.w   L_nr2,r3
        cmp/hs  r3,r2
        bt      30f              ! farther than NEAR_R
        mov     #1,r4
        mov.l   r4,@(52,r6)      ! kind 1: 1,000 medal
30:     mov.l   L_kset,r0
        jmp     @r0
        nop
L_nr2:  .word   NEAR_R*NEAR_R
        .align 2
L_hb:   .long   0x0C7E86FC
L_kset: .long   0x0C228960

! ---- collect wrapper (called instead of AddScore(r4 player, r5 value, r6) at 0x0C22A0DA; r9 = item).
! For gold (item kind at +0x34 is 0-2): count the HIT first (AddHit(1)), then make the piece worth
!   medal score (item+0x50) x HIT count (0x0CB363F8) / 10
! and write that back into item+0x50 before adding it. The collect code reads item+0x50 again for the
! gold score display (0x0C27B670) and the trailing popup (0x0C22A320), so both show the same amount.
! Other items: AddScore unchanged.
        .org 0x480
wrap:
        mov.l   @(52,r9),r0      ! item kind
        mov     #2,r1
        cmp/hi  r1,r0            ! kind > 2 -> not gold
        bt      3f
        sts.l   pr,@-r15
        mov.l   r4,@-r15
        mov.l   L_addhit,r0
        jsr     @r0
        mov     #1,r4            ! HIT + 1
        mov.l   L_hitcnt,r1
        mov.l   @r1,r1           ! hit score (including this piece)
        mov     r9,r2
        add     #0x50,r2
        mov.l   @r2,r5           ! medal score
        mul.l   r1,r5
        sts     macl,r5          ! medal x hit
        mov.l   L_div10,r1
        dmulu.l r1,r5
        sts     mach,r5
        shlr2   r5
        shlr    r5               ! / 10  (x * 0xCCCCCCCD >> 35)
        mov.l   r5,@r2           ! item value (read again for gold score + popup)
        mov.l   @r15+,r4
        lds.l   @r15+,pr
        mov     #0,r6
3:      mov.l   L_addscore,r0
        jmp     @r0              ! AddScore(r4, r5, r6)
        nop
        .align 2
L_addhit:   .long 0x0C27B500
L_hitcnt:   .long 0x0CB363F8
L_addscore: .long 0x0C1F8B20
L_div10:    .long 0xCCCCCCCD

! ---- HIT resets each stage. The scene-change routine at 0x0C1F0E10 (game start r4 = 0x15, next
! stage r4 = 0x16, and its other scene changes) calls 0x0C1FD750 through the pointer at 0x0C1F0F0C;
! this wrapper clears the HIT count (0x0CB363F8) and continues to 0x0C1FD750.
        .org 0x4E0
stgclr:
        mov.l   L_hitcnt2,r1
        mov     #0,r0
        mov.l   r0,@r1
        mov.l   L_scene,r1
        jmp     @r1
        nop
        .align 2
L_hitcnt2:  .long 0x0CB363F8
L_scene:    .long 0x0C1FD750

! ---- long patches
        .org 0x600
        .long 0xAC22A104, 0xA03F0480   ! item collect: AddScore -> our wrapper
        .long 0xAC2299D8, 0xA03F0140   ! orbit entry: random() call -> our state chooser
        .long 0xAC226F14, 0xA03F0400   ! SpawnItem: per-kind setup call -> wrapper (100 medal near the player -> 1,000)
        .long 0xAC1F0F0C, 0xA03F04E0   ! scene change (game start / next stage): 0x0C1FD750 -> wrapper that clears HIT first
        .long 0xAC1FF3DC, 0xA03F0200   ! bullet manager: literal for the jsr above (was add #-1,r1 / mov.l r1,@(r0,r8))
        .long 0xAC227F50, 0xA03F0280   ! energy item init: main routine 0x0C228A60 -> our wrapper (energy only)
