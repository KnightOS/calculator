init_ui:
    pcall(getLcdLock)
    pcall(allocScreenBuffer)
    kld((screen_buffer), iy)
    ret

redraw_ui:
    kld(iy, (screen_buffer))
    kld(hl, .window_title)
    ld a, 0b100
    corelib(drawWindow)
    ret
.window_title:
    .db "Calculator", 0

screen_buffer:
    .dw 0
