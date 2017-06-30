parse_expr:
    ; Free existing lists, if present
    ex de, hl
    ld bc, 0
    kld(hl, (token_queue))
    pcall(cpHLBC)
    pcall(nz, free)
    kld(hl, (operator_stack))
    pcall(cpHLBC)
    pcall(nz, free)

    ; Set up new lists
    ld bc, 0x100
    pcall(malloc)
    ret nz
    kld((token_queue), ix)
    kld((.current_token), ix)
    xor a
    ld (ix), a
    push ix \ pop iy
    pcall(malloc)
    ret nz
    kld((operator_stack), ix)
    kld((.current_op), ix)
    ld (ix), a
    ; IX: current_token, IY: current_operator
    ld hl, 0x100
    kld((token_queue + 2), hl)
    kld((operator_stack + 2), hl)

    ex de, hl
.loop:
    ld a, (hl)
    or a
    ret z ; end of expression

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
.continue:
    inc hl
    jr .loop
.current_token:
    .dw 0
.current_op:
    .dw 0
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
    ld a, 21
    kcall(.ensure_buffer)
    ld a, NODE_NUMBER
    ld (ix), a
    inc ix
    push hl
        push ix \ pop hl
        ld d, h \ ld e, l
        inc de
        xor a
        ld (hl), a
        ld bc, 20
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
    ld bc, 20
    add ix, bc
    jr $
    kjp(.loop)
.parse_operator:
    ld b, 0x34
    jr $
    jr .continue
.ensure_buffer:
    ; TODO
    ret

token_queue:
    .dw 0, 0 ; addr, size
operator_stack:
    .dw 0, 0 ; addr, size

operators:
    ;db string, operation, flags << 4 | precedence, function
    ;flags: bit 0: unary; 1: right associative
    .db plus_str,          OP_UNARY_PLUS, (0b11 << 4) | 3
    .dw _op_unary_plus
    .db minus_str,         OP_UNARY_MINUS, (0b11 << 4) | 3
    .dw _op_unary_minus
    .db logical_not_str,   OP_LOGICAL_NOT, (0b11 << 4) | 3
    .dw _op_logical_not
    .db multiply_str,      OP_MULTIPLY, (0b00 << 4) | 5
    .dw _op_multiply
    .db divide_str,        OP_DIVIDE, (0b00 << 4) | 5
    .dw _op_divide
    .db modulo_str,        OP_MODULO, (0b00 << 4) | 5
    .dw _op_modulo
    .db plus_str,          OP_PLUS, (0b00 << 4) | 6
    .dw _op_plus
    .db minus_str,         OP_MINUS, (0b00 << 4) | 6
    .dw _op_minus
    .db lte_str,           OP_LESS_THAN_OR_EQUAL_TO, (0b00 << 4) | 8
    .dw _op_less_or_equal
    .db gte_str,           OP_GREATER_THAN_OR_EQUAL_TO, (0b00 << 4) | 8
    .dw _op_greater_or_equal
    .db less_than_str,     OP_LESS_THAN, (0b00 << 4) | 8
    .dw _op_less_than
    .db greater_than_str,  OP_GREATER_THAN, (0b00 << 4) | 8
    .dw _op_greater_than
    .db equal_to_str,      OP_EQUAL_TO, (0b00 << 4) | 9
    .dw _op_equal_to
    .db not_equal_to_str,  OP_NOT_EQUAL_TO, (0b00 << 4) | 9
    .dw _op_not_equal_to
    .db logical_and_str,   OP_LOGICAL_AND, (0b00 << 4) | 13
    .dw _op_logical_and
    .db logical_or_str,    OP_LOGICAL_OR, (0b00 << 4) | 14
    .dw _op_logical_or
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
    .db "+-!*/%<>=&|", 0
