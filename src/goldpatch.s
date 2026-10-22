! Akai Katana gold patch: boot hook + gold-collect wrapper (u4 offset 0x3F0000, CPU 0xA03F0000)
        .text
        .org 0
! ---- boot hook: called instead of 0x0C1DE164 (after the program is unpacked into RAM).
! Installs the permanent patches (title-screen mode menu, game-start hook, boot-screen text). The
! LIMITED+ patches are written (or the original values put back, for ARCADE MODE) by "apply" when a
! game starts; the original values are listed next to each table (0x360, 0x628).
        .equ MV,   0x0C7FF000    ! menu vars: +0 cursor (0 = ARCADE MODE, 1 = LIMITED+), +4 last input, +8 mode in use
        .equ SW_WN, 12
        .equ SW_LN, 5
        .equ PM_WN, 3
        .equ PM_LN, 4
hook:
        mov.l   L_pwt,r1         ! permanent word patches
        mov     #PM_WN,r3
4:      mov.l   @r1+,r2
        mov.l   @r1+,r4
        dt      r3
        bf/s    4b
        mov.w   r4,@r2
        mov.l   L_plt,r1         ! permanent long patches
        mov     #PM_LN,r3
5:      mov.l   @r1+,r2
        mov.l   @r1+,r4
        dt      r3
        bf/s    5b
        mov.l   r4,@r2
        mov.l   L_mv0,r1         ! menu vars: cursor on ARCADE MODE, nothing applied
        mov     #0,r0
        mov.l   r0,@r1
        mov.l   r0,@(4,r1)
        mov.l   r0,@(8,r1)
        mov.l   L_bdst,r1        ! warning-screen text (0x0C3042D4..0x0C3045F3) from 0xA03F0700
        mov.l   L_bsrc,r2
        mov.w   L_blen,r3
3:      mov.b   @r2+,r0
        mov.b   r0,@r1
        dt      r3
        bf/s    3b
        add     #1,r1
        mov.l   L_orig,r0        ! continue with the original call (pr still returns to boot)
        jmp     @r0
        nop
L_blen: .word   0x320
        .align 2
L_pwt:  .long   0xA03F06C0
L_plt:  .long   0xA03F0680
L_mv0:  .long   MV
L_orig: .long   0x0C1DE164
L_bdst: .long   0xAC3042D4
L_bsrc: .long   0xA03F0700

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

! ---- switchable word patches (address, LIMITED+ value); originals saved at boot
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
! ---- original values for the switchable word patches above (same order; ARCADE MODE)
        .org 0x360
        .long 0xE402
        .long 0xE602
        .long 0x4A0B
        .long 0x1B55
        .long 0x1205
        .long 0x0640
        .long 0x90B1
        .long 0x018E
        .long 0x2118
        .long 0x8D03
        .long 0x6B83
        .long 0x890F

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

! ---- game start / next stage. The scene-change routine at 0x0C1F0E10 calls 0x0C1FD750 through the
! pointer at 0x0C1F0F0C (permanent patch). At game start (r4 = 0x15) the chosen mode is applied. In
! LIMITED+ the HIT count (0x0CB363F8) is cleared at every scene change (game start, next stage).
        .org 0x4E0
stgclr:
        mov     r4,r0
        cmp/eq  #0x15,r0
        bf      61f
        sts.l   pr,@-r15
        mov.l   r4,@-r15
        mov.l   r5,@-r15
        mov.l   L_apply,r0
        jsr     @r0
        nop
        mov.l   @r15+,r5
        mov.l   @r15+,r4
        lds.l   @r15+,pr
61:     mov.l   L_mv1,r1
        mov.l   @(8,r1),r0       ! mode in use
        tst     r0,r0
        bt      62f
        mov.l   L_hitcnt2,r1
        mov     #0,r0
        mov.l   r0,@r1
62:     mov.l   L_scene,r1
        jmp     @r1
        nop
        .align 2
L_apply:    .long 0xA03F0E80
L_mv1:      .long MV
L_hitcnt2:  .long 0x0CB363F8
L_scene:    .long 0x0C1FD750

! ---- switchable long patches (address, LIMITED+ value); originals saved at boot
        .org 0x600
        .long 0xAC22A104, 0xA03F0480   ! item collect: AddScore -> our wrapper
        .long 0xAC2299D8, 0xA03F0140   ! orbit entry: random() call -> our state chooser
        .long 0xAC226F14, 0xA03F0400   ! SpawnItem: per-kind setup call -> wrapper (100 medal near the player -> 1,000)
        .long 0xAC1FF3DC, 0xA03F0200   ! bullet manager: literal for the jsr above (was add #-1,r1 / mov.l r1,@(r0,r8))
        .long 0xAC227F50, 0xA03F0280   ! energy item init: main routine 0x0C228A60 -> our wrapper (energy only)

! ---- original values for the switchable long patches above (same order; ARCADE MODE)
        .org 0x628
        .long 0x0C1F8B20
        .long 0x0C1E4190
        .long 0x0C228960
        .long 0x71FF0816
        .long 0x0C228A60

! ---- permanent long patches (address, value), always installed at boot
        .org 0x680
        .long 0xAC1F0F0C, 0xA03F04E0   ! scene change (game start / next stage): 0x0C1FD750 -> stgclr
        .long 0xAC304158, 0x32362E31   ! memory-check screen date: "      2010. 8.13" -> "      2026.10.22"
        .long 0xAC30415C, 0x302E3232   !   (second half)
        .long 0xAC2220E8, 0xA03F0C00   ! title: literal for the menu jump below (was 0x00806020, only used at 0x0C221F34)
! ---- permanent word patches
        .org 0x6C0
        .long 0xAC221F30, 0xD06D       ! title rank/score block entry: mov.l @(0x0C2220E8),r0
        .long 0xAC221F32, 0x402B       !   jmp @r0  (-> menu)
        .long 0xAC221F34, 0x0009       !   nop

! ---- warning screen text and version line (copied by the boot hook; see tools/warntext.py)
        .org 0x700
        .include "src/warntext.s"

! ---- title-screen mode menu. Jumped to from the start of the title's rank/score block (0x0C221F30).
! No credits: run the original block (set r10/r8/r4 as the replaced instructions did, continue at
! 0x0C221F36). With credits: draw ARCADE MODE / LIMITED+ in the block's place (same font 0xF0, same
! outline as the rank line), move the cursor with up/down, and continue at 0x0C2220C8 (end of the block).
        .equ MX,  108
        .equ MY0, 124
        .equ MY1, 140
        .org 0xC00
menu:
        mov.l   L_cred,r1
        mov.l   @r1,r0           ! credits
        tst     r0,r0
        bf      70f
        mov.l   L_c104,r10       ! original block
        mov.l   L_cec0,r8
        mov.l   L_tint,r4
        mov.l   L_back1,r0
        jmp     @r0
        nop
70:     mov.l   L_inp,r1
        mov.w   @r1,r2
        extu.w  r2,r2            ! P1 held: bit 0 up, bit 1 down
        mov.l   L_mv2,r9
        mov.l   @(4,r9),r3
        mov.l   r2,@(4,r9)
        not     r3,r3
        and     r3,r2            ! newly pressed
        mov     r2,r0
        tst     #1,r0
        bt      71f
        mov     #0,r1
        mov.l   r1,@r9           ! up: ARCADE MODE
71:     mov     r2,r0
        tst     #2,r0
        bt      72f
        mov     #1,r1
        mov.l   r1,@r9           ! down: LIMITED+
72:     mov.l   @r9,r0
        mov     #0,r12
        tst     r0,r0
        movt    r12              ! r12 = 1 if ARCADE MODE selected
        mov.l   L_s0a,r10
        tst     r12,r12
        bt      73f
        mov.l   L_s0b,r10
73:     bsr     item
        mov     #MY0,r11
        mov.l   @r9,r12          ! r12 = 1 if LIMITED+ selected
        mov.l   L_s1a,r10
        tst     r12,r12
        bt      74f
        mov.l   L_s1b,r10
74:     bsr     item
        mov     #MY1,r11
        mov.l   L_back2,r0
        jmp     @r0
        nop
! draw string r10 at (MX, r11), yellow if r12 != 0 else grey, with the rank line's dark outline
item:
        extu.b  r11,r11          ! y (loaded with an 8-bit immediate)
        sts.l   pr,@-r15
        mov.l   L_c118,r0
        jsr     @r0              ! current tint
        nop
        mov.l   r0,@-r15
        mov.l   L_c104,r0
        mov.l   L_outl,r4
        jsr     @r0
        nop
        mov.l   L_print,r8
        mov     #MX+1,r4
        mov     r11,r5
        add     #-1,r5
        mov.w   L_f0,r6
        jsr     @r8
        mov     r10,r7
        mov     #MX-1,r4
        mov     r11,r5
        add     #1,r5
        mov.w   L_f0,r6
        jsr     @r8
        mov     r10,r7
        mov     #MX-1,r4
        mov     r11,r5
        add     #-1,r5
        mov.w   L_f0,r6
        jsr     @r8
        mov     r10,r7
        mov     #MX+1,r4
        mov     r11,r5
        add     #1,r5
        mov.w   L_f0,r6
        jsr     @r8
        mov     r10,r7
        mov.l   L_tint,r4        ! selected: yellow
        tst     r12,r12
        bf      75f
        mov.l   L_grey,r4        ! not selected: grey
75:     mov.l   L_c104,r0
        jsr     @r0
        nop
        mov     #MX,r4
        mov     r11,r5
        mov.w   L_f0,r6
        jsr     @r8
        mov     r10,r7
        mov.l   @r15+,r4         ! restore tint
        mov.l   L_c104,r0
        jsr     @r0
        nop
        lds.l   @r15+,pr
        rts
        nop
L_f0:   .word   0xF0
        .align 2
L_cred:  .long  0x0C1E0D7C
L_inp:   .long  0x0C1DC9BE
L_mv2:   .long  MV
L_c104:  .long  0x0C1DD104
L_c118:  .long  0x0C1DD118
L_cec0:  .long  0x0C1ECEC0
L_print: .long  0x0C1DD12C
L_tint:  .long  0x00806020
L_outl:  .long  0x002A200A
L_grey:  .long  0x00606060
L_back1: .long  0x0C221F36
L_back2: .long  0x0C2220C8
L_s0a:   .long  0xA03F0E00
L_s0b:   .long  0xA03F0E10
L_s1a:   .long  0xA03F0E20
L_s1b:   .long  0xA03F0E30
        .org 0xE00
        .asciz  "  ARCADE MODE"
        .org 0xE10
        .asciz  "> ARCADE MODE"
        .org 0xE20
        .asciz  "  LIMITED+"
        .org 0xE30
        .asciz  "> LIMITED+"

! ---- apply the chosen mode at game start: LIMITED+ writes the switchable patches, ARCADE MODE puts
! the original values back. Writes go through cached P1 addresses (0x8C...) so the CPU sees new code.
        .org 0xE80
apply:
        mov.l   L_mv3,r6
        mov.l   @r6,r7           ! cursor
        mov.l   r7,@(8,r6)       ! mode in use
        mov.l   L_p1m,r6
        mov.l   L_swt2,r1
        mov     #SW_WN,r3
        mov.l   L_sow2,r5        ! original word values
80:     mov.l   @r1+,r2
        mov.l   @r1+,r4
        and     r6,r2            ! 0xAC... -> 0x8C...
        tst     r7,r7
        bf      81f
        mov.l   @r5,r4           ! ARCADE MODE: original
81:     mov.w   r4,@r2
        dt      r3
        bf/s    80b
        add     #4,r5
        mov.l   L_slt2,r1
        mov     #SW_LN,r3
        mov.l   L_sol2,r5        ! original long values
82:     mov.l   @r1+,r2
        mov.l   @r1+,r4
        and     r6,r2
        tst     r7,r7
        bf      83f
        mov.l   @r5,r4
83:     mov.l   r4,@r2
        dt      r3
        bf/s    82b
        add     #4,r5
        rts
        nop
        .align 2
L_mv3:  .long   MV
L_p1m:  .long   0xDFFFFFFF
L_swt2: .long   0xA03F0300
L_slt2: .long   0xA03F0600
L_sow2: .long   0xA03F0360
L_sol2: .long   0xA03F0628
