ASM = z80asm-gnu

SRCS =
SRCS += 00-variables.asm
SRCS += 01-interrupts.asm
SRCS += 02-init.asm

MAIN = oz-rc2014.bin
ROM_SIZE = 8192

all: $(MAIN)

kernel.bin: kernel.asm $(SRCS)
	$(ASM) -o $@ $<

$(MAIN): kernel.bin
	cp kernel.bin $(MAIN)
	./padd.sh $(MAIN) $(ROM_SIZE)

clean:
	rm -f kernel.bin $(MAIN)
