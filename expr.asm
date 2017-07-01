parser_init:
    ; Allocate buffers
    ld bc, 100
    pcall(malloc)
    ret nz
    kld((token_queue), ix)
    xor a
    ld (ix), a
    push ix \ pop iy
    pcall(malloc)
    ret nz
    kld((operator_stack), ix)
    ld (ix), a
    kld((token_queue + 2), bc)
    kld((operator_stack + 2), bc)
    ; Pre-relocate operator info
    kld(hl, operators)
    kld(de, end@operators)
.loop:
    push de
        ld e, (hl)
        inc hl
        ld d, (hl)
        ex de, hl
        kld(bc, 0)
        add hl, bc
        ex de, hl
        ld (hl), d
        dec hl
        ld (hl), e
    pop de
    ld bc, 6
    add hl, bc
    pcall(cpHLDE)
    jr nz, .loop
    ret

parse_expr:
    kld(ix, (token_queue))
    kld((.current_token), ix)
    kld(iy, (operator_stack))
    kld((.current_op), iy)
    ; zero out previous buffer contents
    push hl
        push ix \ pop hl
        ld d, h \ ld e, l
        inc de
        kld(bc, (operator_stack + 2))
        ldir
        push iy \ pop hl
        ld d, h \ ld e, l
        inc de
        kld(bc, (token_queue + 2))
        ldir
    pop hl
.loop:
    ld a, (hl)
    or a
    kjp(z, .finalize)

    kcall(.is_digit)
    jr z, .parse_digit
_:  ; if A in operator_chars
    ld b, a
    ex de, hl
    kld(hl, operator_chars)
    pcall(strchr)
    ex de, hl
    ld a, b
    jr z, .parse_operator
    ; Ignore anything else (TODO: error here)
    inc hl
    jr .loop
.is_digit:
    cp '9'
    jr z, _
    ret nc
    cp '0'
    ret c
_:  cp a
    ret
.parse_digit:
    ; We look for the end of the number, then shove a zero in there and hand
    ; the whole thing to strtofp.
    ld a, 10
    kcall(.ensure_buffer)
    ; NODE_NUMBER is just followed by a 9 byte float
    ld a, NODE_NUMBER
    ld (ix), a
    inc ix
    push hl
        push ix \ pop hl
        ld d, h \ ld e, l
        inc de
        xor a
        ld (hl), a
        ld bc, 9
        ldir
    pop hl \ push hl
        inc hl
.digit_loop:
        ld a, (hl)
        kcall(.is_digit)
        jr z, _
        cp '.'
        jr nz, .commit_number
_:      inc hl
        jr .digit_loop
.commit_number:
        ld a, (hl)
        ld b, a
        xor a
        ld (hl), a
        ex de, hl
    pop hl
    push bc
    push hl
    push ix
        push ix \ push hl \ pop ix \ pop hl
        pcall(strtofp)
    pop ix
    pop hl
    pop bc
    ld h, d \ ld l, e
    ld a, b
    ld (hl), a
    ld bc, 9
    add ix, bc
    kjp(.loop)
.parse_operator:
    ex de, hl
    push ix
        kld(ix, operators)
.find_operator:
        ld l, (ix)
        ld h, (ix + 1)
        kcall(expr_strcmp)
        jr z, .op_found
        ld bc, 6 ; size of op entry
        add ix, bc
        jr .find_operator
        ; Note: due to checks in the main loop we are guaranteed to find an
        ; operator, so we don't handle the not found case in this loop
.op_found:
        push ix \ pop hl
    pop ix
    ; HL is a pointer to this operator's entry in the operator table
    push de
        push hl
            kld(hl, (operator_stack))
            push iy \ pop de
            pcall(cpHLDE)
            ; Don't test the previous operation
            jr z, .empty_stack
        pop hl
        ; Check to see if we need to commit the previous op
        ; TODO
        jr _
.empty_stack:
        pop hl
_:      ; Push this to the operator stack
        ld (iy), l
        ld (iy + 1), h
        inc iy \ inc iy
    pop hl
    inc hl
    kjp(.loop)
.ensure_buffer:
    ; TODO
    ret
.finalize:
    kld(bc, (operator_stack))
    push iy \ pop hl
    ld a, NODE_OPERATOR
.pop_ops:
    pcall(cpHLBC)
    ret z
    ld d, (hl)
    dec hl
    ld e, (hl)
    dec hl
    ld (ix), a
    ld (ix + 1), e
    ld (ix + 2), d
    inc ix \ inc ix \ inc ix
    jr .pop_ops
; TODO: We can probably eliminate these vars at some point
.current_token:
    .dw 0
.current_op:
    .dw 0

token_queue:
    .dw 0, 0 ; addr, size
operator_stack:
    .dw 0, 0 ; addr, size

; Like strcmp but only tests until DE's string ends
expr_strcmp:
    push hl
    push de
.loop:
        ld a, (hl)
        or a
        jr z, .done
        ex de, hl
        cp (hl)
        ex de, hl
        jr nz, .done
        inc de \ inc hl
        jr .loop
.done:
    pop de
    pop hl
    ret

operators:
    ;db string, operation, flags << 4 | precedence, function
    ;flags: bit 0: unary; 1: right associative
    ;.dw plus_str
    ;.db OP_UNARY_PLUS, (0b11 << 4) | 3
    ;.dw _op_unary_plus
    ;.dw minus_str
    ;.db OP_UNARY_MINUS, (0b11 << 4) | 3
    ;.dw _op_unary_minus
    ;.dw logical_not_str
    ;.db OP_LOGICAL_NOT, (0b11 << 4) | 3
    ;.dw _op_logical_not
    .dw multiply_str
    .db OP_MULTIPLY, (0b00 << 4) | 5
    .dw _op_multiply
    .dw divide_str
    .db OP_DIVIDE, (0b00 << 4) | 5
    .dw _op_divide
    ;.dw modulo_str
    ;.db OP_MODULO, (0b00 << 4) | 5
    ;.dw _op_modulo
    .dw plus_str
    .db OP_PLUS, (0b00 << 4) | 6
    .dw _op_plus
    .dw minus_str
    .db OP_MINUS, (0b00 << 4) | 6
    .dw _op_minus
    ;.dw lte_str
    ;.db OP_LESS_THAN_OR_EQUAL_TO, (0b00 << 4) | 8
    ;.dw _op_less_or_equal
    ;.dw gte_str
    ;.db OP_GREATER_THAN_OR_EQUAL_TO, (0b00 << 4) | 8
    ;.dw _op_greater_or_equal
    ;.dw less_than_str
    ;.db OP_LESS_THAN, (0b00 << 4) | 8
    ;.dw _op_less_than
    ;.dw greater_than_str
    ;.db OP_GREATER_THAN, (0b00 << 4) | 8
    ;.dw _op_greater_than
    ;.dw equal_to_str
    ;.db OP_EQUAL_TO, (0b00 << 4) | 9
    ;.dw _op_equal_to
    ;.dw not_equal_to_str
    ;.db OP_NOT_EQUAL_TO, (0b00 << 4) | 9
    ;.dw _op_not_equal_to
    ;.dw logical_and_str
    ;.db OP_LOGICAL_AND, (0b00 << 4) | 13
    ;.dw _op_logical_and
    ;.dw logical_or_str
    ;.db OP_LOGICAL_OR, (0b00 << 4) | 14
    ;.dw _op_logical_or
.end:
plus_str:
    .db "+", 0
minus_str:
    .db "-", 0
logical_not_str:
    .db "!", 0
multiply_str:
    .db "*", 0
divide_str:
    .db "/", 0
modulo_str:
    .db "%", 0
lte_str:
    .db "<=", 0
gte_str:
    .db ">=", 0
less_than_str:
    .db "<", 0
greater_than_str:
    .db ">", 0
equal_to_str:
    .db "==", 0
not_equal_to_str:
    .db "!=", 0
logical_and_str:
    .db "&", 0
logical_or_str:
    .db "|", 0
operator_chars:
    ;.db "+-!*/%<>=&|", 0
    .db "+-*/", 0
