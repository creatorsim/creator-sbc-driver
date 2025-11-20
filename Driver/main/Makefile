CC = riscv64-linux-gnu-gcc
CFLAGS = -march=rv64gc -mabi=lp64d -g -O2

ASM_SOURCES = program.s ecall_macros.s
ASM_OBJS = $(ASM_SOURCES:.s=.o)
C_SOURCES = ecall.c
C_OBJS = $(C_SOURCES:.c=.o)

TARGET = program

all: build

build: $(TARGET)
	rm -f $(ASM_OBJS) $(C_OBJS)

$(TARGET): $(ASM_OBJS) $(C_OBJS)
	$(CC) $(ASM_OBJS) $(C_OBJS) -o $@ -static

%.o: %.s
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(ASM_OBJS) $(C_OBJS) $(TARGET)
