include .knightos/variables.make
INCLUDE:=$(INCLUDE);include;.

ALL_TARGETS:=$(BIN)calculator

$(BIN)calculator: *.asm
	mkdir -p $(BIN)
	$(AS) $(ASFLAGS) --listing $(BIN)main.list main.asm $(BIN)calculator

include .knightos/sdk.make
