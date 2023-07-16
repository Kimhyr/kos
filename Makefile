SOURCE := source
BUILD := build
OBJECTS := boot.o
OBJECTS := $(addprefix $(BUILD)/,$(OBJECTS))
CLEAN := boot.bin $(OBJECTS)

CC := clang++
AS := nasm
LD := ld
EM := qemu-system-x86_64

LFLAGS := \
	-T $(SOURCE)/script.ld \
	-m elf_x86_64
CFLAGS := \
	-Wall \
	-Wextra \
	-std=c++20 \
	-O3 \
	-target x86_64-elf \
	-masm=intel \
	-ffreestanding \
	-fno-threadsafe-statics \
	-fno-rtti \
	-fno-exceptions
AFLAGS := \
	-f elf64
EFLAGS :=

.PHONY: boot
boot: $(BUILD)/boot.bin
$(BUILD)/boot.bin: $(OBJECTS)
	$(LD) $(LFLAGS) -o $@ $^
	objcopy -O binary $@ $@

$(BUILD)/%.o: $(SOURCE)/%.cpp
	$(CC) $(CFLAGS) -o $@ -c $^

$(BUILD)/%.o: $(SOURCE)/%.s
	$(AS) $(AFLAGS) -o $@ $^

$(BUILD):
	mkdir -p $@

.PHONY: em
em: $(BUILD)/boot.bin
	$(EM) $(EFLAGS) $^

clean:
	rm -f $(CLEAN)
