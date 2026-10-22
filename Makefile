AS=sh-elf-as
OBJCOPY=sh-elf-objcopy
U4?=u4.orig

all: build/u4

build/goldpatch.bin: src/goldpatch.s
	mkdir -p build
	$(AS) --big -o build/goldpatch.o $<
	$(OBJCOPY) -O binary build/goldpatch.o $@

build/u4: build/goldpatch.bin tools/build.py
	python3 tools/build.py $(U4) build/goldpatch.bin $@

clean:
	rm -rf build
