#include "kernel.inc"
#include "corelib.inc"
#include "expr.inc"
    .db "KEXC"
    .db KEXC_ENTRY_POINT
    .dw start
    .db KEXC_STACK_SIZE
    .dw 64
    .db KEXC_NAME
    .dw name
    .db KEXC_HEADER_END
name:
    .db "Calculator", 0
start:
    kld(de, corelib_path)
    pcall(loadLibrary)

    pcall(getKeypadLock)

    kcall(parser_init)

    kcall(init_ui)
    kcall(redraw_ui)

    kld(hl, .test_expr)
    ld de, 0x0808
    pcall(drawStr)
    kcall(parse_expr)
    kcall(eval_expr)

    ld a, 0xF
    kld(ix, result)
    kld(hl, .output_str)
    pcall(fptostr)

    kld(iy, (screen_buffer))
    ld de, 0x080F
    pcall(drawStr)
    jr main_loop
.test_expr:
    .db "1.234+4.321", 0
.output_str:
    .block 20

main_loop:
    kld(iy, (screen_buffer))
.loop:
    pcall(fastCopy)

    pcall(flushKeys)
    corelib(appWaitKey)

    cp kMODE
    jr nz, .loop
    ret

corelib_path:
    .db "/lib/core", 0
window_title:
    .db "Calculator", 0

#include "ui.asm"
#include "expr.asm"
#include "operations.asm"
