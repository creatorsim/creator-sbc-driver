
#
# Creator (https://creatorsim.github.io/creator/)
#
.text
.type main, @function
.globl main
.extern printf


.data
    msg: .string "Hola soy OrangePi"

.text

main:
    li a7, 64       # syscall write
    li a0, 1        # fd = stdout
    la a1, msg
    li a2, 17       # longitud del mensaje
    ecall

    jr ra
