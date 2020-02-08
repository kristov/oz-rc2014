Z8T=../z8t/z8t.pl
ASM=--asm='~/bin/z80asm-gnu -o <BIN> <ASM>'

TESTS =
TESTS += 03-main-KFN.z8t
TESTS += 04-ringbuf-SPACE.z8t
TESTS += 04-ringbuf-READ.z8t
TESTS += 04-ringbuf-WRITE.z8t
TESTS += 04-ringbuf-READM.z8t
TESTS += 04-ringbuf-WRITEM.z8t

all: $(TESTS)
	$(Z8T) $(ASM) $(TESTS)
