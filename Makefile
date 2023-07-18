SOURCE := source
BUILD := build
OBJECTS := boot.o
OBJECTS := $(addprefix $(BUILD)/,$(OBJECTS))
CLEAN := boot.bin $(OBJECTS)
LSCRIPT := $(SOURCE)/script.ld

AS := nasm
LD := ld
EM := qemu-system-x86_64

LFLAGS := \
	-T $(LSCRIPT) \
	-m elf_x86_64
AFLAGS := \
	-f elf64

.PHONY: init
init: $(BUILD)

.PHONY: all
all: boot

.PHONY: boot
boot: $(BUILD)/boot.bin
$(BUILD)/boot.bin: $(OBJECTS)
	$(LD) $(LFLAGS) -o $@ $^
	objcopy -O binary $@ $@

$(BUILD)/%.o: $(SOURCE)/%.s
	$(AS) $(AFLAGS) -o $@ $^

$(BUILD):
	mkdir -p $@

.PHONY: em
em: $(BUILD)/boot.bin
	$(EM) -drive file=$^,format=raw,index=0,media=disk

clean:
	rm -f $(CLEAN)
