.macro print_int a0_reg
    la t1, buffer_end       # Apuntar al final del buffer
    mv t6, t1               # Guardar puntero final para restaurar luego
    li t2, 0                # contador dígitos
    li t5, 0                # limpiar flag negativo
    mv t0, \a0_reg          # copiar número

    bltz t0, .Lhandle_neg\@

.Lcheck_zero\@:
    beqz t0, .Lprint_zero\@
    j .Lconvert_loop\@

.Lhandle_neg\@:
    neg t0, t0
    li t5, 1

.Lconvert_loop\@:
    la t1, buffer_end
    li t2, 0

.Lloop\@:
    li t3, 10
    rem t4, t0, t3
    addi t4, t4, '0'
    addi t1, t1, -1
    sb t4, 0(t1)
    div t0, t0, t3
    addi t2, t2, 1
    bnez t0, .Lloop\@

    j .Lprint_number\@

.Lprint_zero\@:
    la t1, buffer_end
    addi t1, t1, -1
    li t4, '0'
    sb t4, 0(t1)
    li t2, 1

.Lprint_number\@:
    li a0, 1

    # Print sign
    beqz t5, .Lprint_digits\@
    li a0, 1
    la a1, minus_sign
    li a2, 1
    li a7, 64
    .word 0x00000073

.Lprint_digits\@:
    mv a1, t1
    mv a2, t2
    li a7, 64
    .word 0x00000073

    # --- Clear buffer loop ---
    la t0, buffer          # inicio del buffer
    la t1, buffer_end      # fin del buffer

.Lclear_loop\@:
    beq t0, t1, .Lclear_done\@
    sb zero, 0(t0)
    addi t0, t0, 1
    j .Lclear_loop\@

.Lclear_done\@:

    # Restaurar t1 al final del buffer original
    mv t1, t6

.endm


.section .bss
buffer:
    .space 20 #riscv64 han print until 20 digits (19 signed)
buffer_end:    
.section .data
minus_sign:
    .ascii "-"
nl: .ascii "\n" 
point: .ascii "."
fmt_string: .ascii "%d.%d"
.section .text
#ifdef RISCV64_ORANGEPIRV2
.macro ecall
    addi sp, sp, -4      #ToDO: Save the right registers
    sw ra, 0(sp)                   

    mv t0, a7              

    li t1, 1
    beq t0, t1, 1f 

    li t1, 2
    beq t0, t1, 2f

    li t1, 3
    beq t0, t1, 3f

    li t1, 4
    beq t0, t1, 4f

    li t1, 5
    beq t0, t1, 5f

    li t1, 6
    beq t0, t1, 6f

    li t1, 7
    beq t0, t1, 7f



    li t1, 8
    beq t0, t1, 8f

    li t1, 10
    beq t0, t1, 10f

    li t1, 11
    beq t0, t1, 11f
    
    li t1, 12
    beq t0, t1, 12f

    j 13f                   # return

1:
    print_int a0
    # newline
    li a0, 1
    la a1, nl
    li a2, 1
    li a7, 64
    .word 0x00000073

    j 13f                   # salto al final o retorno


2:
    # # Take int part 
    # fcvt.w.s t0, fa0, rtz

    # print_int t0

    # #Print point    # newline
    # li a0, 1
    # la a1, point
    # li a2, 1
    # li a7, 64
    # .word 0x00000073

    
    # #Take decimal part
    # fcvt.s.w ft0, t0, rtz
    # fsub.s ft1, fa0, ft0
    # li t1, 1000 #Checkout precision
    # fcvt.s.w ft2, t1
    # fmul.s ft3, ft1, ft2
    # fcvt.w.s t1, ft3, rtz
    # # #Print
    # print_int t1

    # li a0, 1
    # la a1, nl
    # li a2, 1
    # li a7, 64
    # .word 0x00000073
       # Take int part 
    fcvt.w.s t0, fa0
    #Take decimal part
    fcvt.s.w ft0, t0
    fsub.s ft1, fa0, ft0
    li t1, 1000 #Checkout precision
    fcvt.s.w ft2, t1
    fmul.s ft3, ft1, ft2
    fcvt.w.s t1, ft3
    #Print
    mv a1, t0
    mv a2, t1 
    la a0, fmt_string
    call printf 


    j 13f 

3:
   # Take int part 
    fcvt.w.d t0, fa0
    #Take decimal part
    fcvt.d.w ft0, t0
    fsub.d ft1, fa0, ft0
    li t1, 1000 #Checkout precision
    fcvt.d.w ft2, t1
    fmul.d ft3, ft1, ft2
    fcvt.w.d t1, ft3
    #Print
    mv a1, t0
    mv a2, t1 
    la a0, fmt_string
    call printf 

    j 13f 

4:
    # Print string
    mv t0, a0
    li t1, 0
.Lcount_loop\@: #count string length
    lbu t2, 0(t0)
    beq t2, zero, .Lcount_done\@ #if \0 founded, the string has been completly riden
    addi t1, t1, 1
    addi t0, t0, 1
    j .Lcount_loop\@
.Lcount_done\@:

    mv a1, a0
    mv a2, t1 #string lenght
    li a0, 1
    li a7, 64 # riscv original write instruction
    .word 0x00000073 # pure ecall!!

    # Print newline
    li a0, 1
    la a1, nl
    li a2, 1
    li a7, 64
    .word 0x00000073

    j 13f
5:
    # Read the line
    li a7, 63       # syscall number for read
    li a0, 0        # fd 0 (stdin)
    la a1, buffer   # address of buffer
    li a2, 20       # number of bytes to read
    .word 0x00000073
    # Process line
    mv t0, a0          # number bytes read
    li s0, 0           # s0 = acumulador del número
    li s1, 0           # s1 = flag signo (0 = +, 1 = -)
    la s2, buffer      # s2 = ptr actual en buffer
    mv s3, t0          # s3 = bytes restantes
    li s4, 0           # s4 = visto_digito (0/1)

.Lparse_loop\@:
    beqz s3, .Lfinish_parse\@   # si se acabó el buffer
    lb t1, 0(s2)                # cargar byte actual
    addi s2, s2, 1
    addi s3, s3, -1

    # si newline o carriage return, terminamos parseo
    li t2, 10
    beq t1, t2, .Lfinish_parse\@
    li t2, 13
    beq t1, t2, .Lparse_loop\@

    # permitir signo solo si aún no se ha visto dígito
    li t2, 45   # '-'
    beq t1, t2, .Lhandle_minus\@
    li t2, 43   # '+'
    beq t1, t2, .Lparse_loop\@

    # comprobar si es dígito '0'..'9'
    li t2, 48
    blt t1, t2, .Lfinish_parse\@
    li t2, 57
    bgt t1, t2, .Lfinish_parse\@

    # convertir ascii a valor
    li t2, 48
    sub t3, t1, t2     # t3 = digit value

    # s0 = s0 * 10 + t3   (usa mul)
    li t4, 10
    mul s0, s0, t4
    add s0, s0, t3

    li s4, 1            # hemos visto al menos 1 dígito
    j .Lparse_loop\@

.Lhandle_minus\@:
    beqz s4, .Lset_minus\@  # si aún no se vio dígito, aceptar signo
    j .Linvalid\@

.Lset_minus\@:
    li s1, 1
    j .Lparse_loop\@

.Lfinish_parse\@:
    beqz s4, .Linvalid\@
    # aplicar signo
    beqz s1, .Lsave_to_register\@
    nop                      # noop placeholder (reemplaza 'sub zero, zero, zero')
    neg s0, s0               # s0 = -s0

.Lsave_to_register\@: 
    mv a0, s0
    j 13f

.Linvalid\@:
    li a0, 0
    j 13f

6:  # Read the line
    li a7, 63       # syscall number for read
    li a0, 0        # fd 0 (stdin)
    la a1, buffer   # address of buffer
    li a2, 20       # number of bytes to read
    .word 0x00000073
    mv t0, a0          # number bytes read
    li s0, 0           # s0 = acumulador parte entera
    li s1, 0           # s1 = flag signo (0 = +, 1 = -)
    la s2, buffer      # s2 = ptr actual en buffer
    mv s3, t0          # s3 = bytes restantes
    li s4, 0           # s4 = visto_digito (0/1)
    li s5,0            # acumulador parte decimal
    li s6, 0       # contador dígitos decimales
    li s7, 0       # flag punto decimal visto (0=no, 1=sí)

.Lparse_loop_float\@:
    beqz s3, .Lfinish_parse_float\@ #Mira si quedan bytes por leer
    lb t1, 0(s2)
    addi s2, s2, 1
    addi s3, s3, -1
 #Analiza el caracter
    # final de línea o nulo
    li t2, 10
    beq t1, t2, .Lfinish_parse_float\@
    li t2, 0
    beq t1, t2, .Lfinish_parse_float\@

    # signo solo si no hemos visto dígitos
    li t2, 45
    beq t1, t2, .Lhandle_minus_float\@
    li t2, 43
    beq t1, t2, .Lparse_loop_float\@

    # si punto decimal
    li t2, 46     # '.'
    beq t1, t2, .Lhandle_dot_float\@

    # dígitos '0'..'9'
    li t2, 48
    blt t1, t2, .Lfinish_parse_float\@
    li t2, 57
    bgt t1, t2, .Lfinish_parse_float\@

    # convertir ascii a número
    li t2, 48
    sub t3, t1, t2

    # Si no hemos visto punto decimal, acumulamos en parte entera (s0)
    beqz s7, .Laccumulate_int_float\@

    # Si ya vimos punto decimal, acumulamos en parte decimal (s5)
    li t4, 10
    mul s5, s5, t4
    add s5, s5, t3
    addi s6, s6, 1    # contador de dígitos decimales
    li s4, 1          # hemos visto dígito
    j .Lparse_loop_float\@

.Laccumulate_int_float\@:
    li t4, 10
    mul s0, s0, t4
    add s0, s0, t3
    li s4, 1
    j .Lparse_loop_float\@

.Lhandle_minus_float\@:
    beqz s4, .Lset_minus_float\@
    j .Linvalid_float\@

.Lset_minus_float\@:
    li s1, 1
    j .Lparse_loop_float\@

.Lhandle_dot_float\@:
    beqz s7, .Lset_dot_float\@
    j .Lfinish_parse_float\@    # si ya había punto, termina parseo

.Lset_dot_float\@:
    li s7, 1
    j .Lparse_loop_float\@

.Lfinish_parse_float\@:
    beqz s4, .Linvalid_float\@

    # Convertir parte entera a float
    fcvt.s.w ft0, s0

    # Convertir parte decimal a float
    fcvt.s.w ft1, s5

    # Calcular divisor = 10^s6
    # Inicializar ft2 = 1.0
    li t2, 1
    fcvt.s.w ft2, t2

    li t3, 0

.pow10_loop_float\@:
    beq t3, s6, .pow10_done_float\@
    li t4, 10
    fcvt.s.w ft3, t4
    fmul.s ft2, ft2, ft3
    addi t3, t3, 1
    j .pow10_loop_float\@

.pow10_done_float\@:
    # dividir parte decimal por divisor
    fdiv.s ft1, ft1, ft2

    # sumar parte entera + parte decimal
    fadd.s ft0, ft0, ft1

    fmv.x.s t5, ft0    # mover bits float final a t5 (entero)
    fmv.x.s t6, ft1    # bits parte decimal en t6
    fmv.x.s t2, ft2    # bits divisor 


    # aplicar signo si s1=1
    beqz s1, .Lsave_float\@
    fneg.s ft0, ft0

.Lsave_float\@:
    # Aquí ft0 tiene el float final

    # Por ejemplo, mover a a0 como entero bit a bit
    fmv.s fa0, ft0

    j 13f

.Linvalid_float\@:
    li a0, 0
    j 13f
7:
    li a7, 63       # syscall number for read
    li a0, 0        # fd 0 (stdin)
    la a1, buffer   # address of buffer
    li a2, 20       # number of bytes to read
    .word 0x00000073
    mv t0, a0          # number bytes read
    li s0, 0           # s0 = acumulador parte entera
    li s1, 0           # s1 = flag signo (0 = +, 1 = -)
    la s2, buffer      # s2 = ptr actual en buffer
    mv s3, t0          # s3 = bytes restantes
    li s4, 0           # s4 = visto_digito (0/1)
    li s5,0            # acumulador parte decimal
    li s6, 0       # contador dígitos decimales
    li s7, 0       # flag punto decimal visto (0=no, 1=sí)

.Lparse_loop_double\@:
    beqz s3, .Lfinish_parse_double\@ #Mira si quedan bytes por leer
    lb t1, 0(s2)
    addi s2, s2, 1
    addi s3, s3, -1
 #Analiza el caracter
    # final de línea o nulo
    li t2, 10
    beq t1, t2, .Lfinish_parse_double\@
    li t2, 0
    beq t1, t2, .Lfinish_parse_double\@

    # signo solo si no hemos visto dígitos
    li t2, 45
    beq t1, t2, .Lhandle_minus_double\@
    li t2, 43
    beq t1, t2, .Lparse_loop_double\@

    # si punto decimal
    li t2, 46     # '.'
    beq t1, t2, .Lhandle_dot_double\@

    # dígitos '0'..'9'
    li t2, 48
    blt t1, t2, .Lfinish_parse_double\@
    li t2, 57
    bgt t1, t2, .Lfinish_parse_double\@

    # convertir ascii a número
    li t2, 48
    sub t3, t1, t2

    # Si no hemos visto punto decimal, acumulamos en parte entera (s0)
    beqz s7, .Laccumulate_int_double\@

    # Si ya vimos punto decimal, acumulamos en parte decimal (s5)
    li t4, 10
    mul s5, s5, t4
    add s5, s5, t3
    addi s6, s6, 1    # contador de dígitos decimales
    li s4, 1          # hemos visto dígito
    j .Lparse_loop_double\@

.Laccumulate_int_double\@:
    li t4, 10
    mul s0, s0, t4
    add s0, s0, t3
    li s4, 1
    j .Lparse_loop_double\@

.Lhandle_minus_double\@:
    beqz s4, .Lset_minus_double\@
    j .Linvalid_double\@

.Lset_minus_double\@:
    li s1, 1
    j .Lparse_loop_float\@

.Lhandle_dot_double\@:
    beqz s7, .Lset_dot_double\@
    j .Lfinish_parse_double\@    # si ya había punto, termina parseo

.Lset_dot_double\@:
    li s7, 1
    j .Lparse_loop_double\@

.Lfinish_parse_double\@:
    beqz s4, .Linvalid_double\@

    # Convertir parte entera a double
    fcvt.d.w ft0, s0

    # Convertir parte decimal a float
    fcvt.d.w ft1, s5

    # Calcular divisor = 10^s6
    # Inicializar ft2 = 1.0
    li t2, 1
    fcvt.d.w ft2, t2

    li t3, 0

.pow10_loop_double\@:
    beq t3, s6, .pow10_done_double\@
    li t4, 10
    fcvt.d.w ft3, t4
    fmul.d ft2, ft2, ft3
    addi t3, t3, 1
    j .pow10_loop_double\@

.pow10_done_double\@:
    # dividir parte decimal por divisor
    fdiv.d ft1, ft1, ft2

    # sumar parte entera + parte decimal
    fadd.d ft0, ft0, ft1

    fmv.x.d t5, ft0    # mover bits float final a t5 (entero)
    fmv.x.d t6, ft1    # bits parte decimal en t6
    fmv.x.d t2, ft2    # bits divisor 


    # aplicar signo si s1=1
    beqz s1, .Lsave_double\@
    fneg.d ft0, ft0

.Lsave_double\@:
    # Aquí ft0 tiene el float final

    # Por ejemplo, mover a a0 como entero bit a bit
    fmv.d fa0, ft0

    j 13f

.Linvalid_double\@:
    li a0, 0
    j 13f

8:
    li a7, 63       # syscall number for read
    mv t0,a0
    mv a2,a1
    mv a1,t0
    li a0, 0
    .word 0x00000073
    j 13f

9: #TODO que hace esto
    li a7, 214  
    li a0, 0
    .word 0x00000073
    j 13f

10:
    li a7, 93       # syscall number for read
    li a0, 0
    .word 0x00000073
    j 13f  

11:
    li a7, 63       # syscall number for read
    li a0, 0        # fd 0 (stdin)
    la a1, buffer   # address of buffer
    li a2, 2      # number of bytes to read
    .word 0x00000073
    lb a0, buffer
    j 13f

12:
    # Print char
    mv a1, a0
    li a0,1
    li a2,1
    li a7,64
    .word 0x00000073      # <-- real ecall without macro

    li a0,1
    la a1, nl       # newline
    li a2,1
    li a7,64
    .word 0x00000073      # <-- real ecall without macro
    j 13f
13:        
    lw ra, 0(sp)           
    addi sp, sp, 4 


.endm
#endif
