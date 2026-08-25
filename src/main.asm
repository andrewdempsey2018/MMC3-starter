.include "header.asm"
.include "macros.asm"
.include "constants.asm"
.include "reset.asm"
.include "nmi.asm"
.include "irq.asm"
.include "controllers.asm"

.segment "ZEROPAGE"
sprite_x: .res 1
sprite_y: .res 1
sleeping: .res 1

.segment "RODATA"
palette_table:
; background
  .byte $0F,$00,$10,$30
  .byte $0F,$01,$21,$31
  .byte $0F,$06,$16,$26
  .byte $0F,$09,$19,$29
; sprites
  .byte $0F,$00,$10,$30
  .byte $0F,$01,$21,$31
  .byte $0F,$06,$16,$26
  .byte $0F,$09,$19,$29
  
.segment "CODE"
main:
; --------------------------------------------------
; Disable nmi/rendering
; --------------------------------------------------
  ldx #$00
  stx PPUCTRL
  stx PPUMASK

; --------------------------------------------------
; Load initial palette
; --------------------------------------------------
  ldx PPUSTATUS
  ldx #$3F
  stx PPUADDR
  ldx #$00
  stx PPUADDR

  ldx #$00
:
  lda palette_table, x
  sta PPUDATA
  inx
  cpx #$20
  bne :-

; --------------------------------------------------
; Init zeropage/bss memory to initial state
; --------------------------------------------------
  lda #$90
  sta sprite_x
  lda #$20
  sta sprite_y

  lda #$00
  sta sleeping
  sta buttons_held
  sta buttons_pressed

; --------------------------------------------------
; Enable maskable interrupts
; --------------------------------------------------
  cli

; --------------------------------------------------
; Enable sprites and background
; --------------------------------------------------
  lda #%00011000 
  sta PPUMASK

; --------------------------------------------------
; NMI on, background at $1000 sprites at $0000
; --------------------------------------------------
  lda #%10010000
  sta PPUCTRL

main_loop:
  inc sprite_y

; --------------------------------------------------
; Draw a sprite: Ypos, Tile, Attributes, Xpos
; --------------------------------------------------
  lda sprite_y
  sta $0200
  lda #$01
  sta $0201
  lda #$00
  sta $0202
  lda sprite_x
  sta $0203

  lda buttons_held
  and #BTN_B
  beq :+
  inc sprite_x
:

; --------------------------------------------------
; Wait until NMI resets 'sleeping' to 0
; --------------------------------------------------
  lda #$01
  sta sleeping

sleep:
  lda sleeping
  bne sleep

  jmp main_loop

.segment "VECTORS"
  .word nmi
  .word reset
  .word irq

.segment "CHRROM"
  .incbin "test_gfx.chr"
