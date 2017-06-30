#include "kernel.inc"
#include "corelib.inc"
#include "expr.inc"
    .db "KEXC"
    .db KEXC_ENTRY_POINT
    .dw start
    .db KEXC_STACK_SIZE
    .dw 20
    .db KEXC_NAME
    .dw name
    .db KEXC_HEADER_END
name:
    .db "Calculator", 0
start:
    kld(de, corelib_path)
    pcall(loadLibrary)

    pcall(getKeypadLock)

    kcall(init_ui)
    kcall(redraw_ui)

    kld(hl, .test_expr)
    kcall(parse_expr)
    jr .loop

.test_expr:
    .db "2+2", 0

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
