.text
.type main, @function
.globl main

.include "ecall_macros.s"

#
# Creator (https://creatorsim.github.io/creator/)
#

.data
    msg:      .string "Hello "
    .align  2          # alinea siguiente dato a 4 bytes (para float)
    number:   .float 2.3
    .align  3          # alinea siguiente dato a 8 bytes (para double)
    number_d: .double 3.4


.text
main:
    # Print int
    li a0, 15
    li a7, 1
    ECALL

    # Print float
    la t0,number
    flw   fa0,  0(t0)
    li a7, 2
    ECALL

    # print double
    la t0,number_d
    fld   fa0,  0(t0)
    li a7, 3
    ECALL
    
    # print string
    la a0, msg
    li a7, 4
    ECALL

    # return 
    jr ra