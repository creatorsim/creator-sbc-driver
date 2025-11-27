CC = riscv64-linux-gnu-gcc
CFLAGS = -march=rv64imafdc -mabi=lp64d -g -O0

ASM_SOURCES = program.s ecall_macros.s
ASM_OBJS = $(ASM_SOURCES:.s=.o)


TARGET = program

all: build

build: $(TARGET)
	rm -f $(ASM_OBJS) 

$(TARGET): $(ASM_OBJS)
	$(CC) $(ASM_OBJS)  -o $@ -static -lc -lm

%.o: %.s
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(ASM_OBJS) $(TARGET)
