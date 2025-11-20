#ifdef RISCV64_ORANGEPIRV2
.macro ECALL
    addi sp, sp, -16       # reservar espacio en pila
    sw ra, 0(sp)           # guardar ra
    sw t0, 4(sp)           # guardar t0

    mv t0, a7              # syscall code en t0

    li t1, 1
    beq t0, t1, 1f

    li t1, 2
    beq t0, t1, 2f

    li t1, 3
    beq t0, t1, 3f

    li t1, 4
    beq t0, t1, 4f

    j 5f                   # si no coincide, ir al fin

1:
    jal ra, print_int
    j 5f

2:
    jal ra, print_float
    j 5f

3:
    jal ra, print_double
    j 5f

4:
    jal ra, print_string
    j 5f

5:
    lw t0, 4(sp)           # restaurar t0
    lw ra, 0(sp)           # restaurar ra
    addi sp, sp, 16        # liberar pila
.endm
#endif
