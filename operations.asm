_op_plus:
    push ix
        ld bc, -10
        add ix, bc
        push ix \ pop iy
        inc iy
        add ix, bc
        inc ix
        kld(hl, result)
        pcall(fpAdd)
    pop ix
    ld bc, 3
    add ix, bc
    ret

_op_unary_plus:
_op_unary_minus:
_op_logical_not:
_op_multiply:
_op_divide:
_op_modulo:
_op_minus:
_op_less_or_equal:
_op_greater_or_equal:
_op_less_than:
_op_greater_than:
_op_equal_to:
_op_not_equal_to:
_op_logical_and:
_op_logical_or:
    ; TODO
    ret
