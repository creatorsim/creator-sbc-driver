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

    # Write double
    li a7, 7
    ecall
    
    li a7,3
    ecall
    
    # return 
    jr ra