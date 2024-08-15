ROOT_DIR   = $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
BUILD_DIR  = $(ROOT_DIR)/build
SOURCE_DIR = $(ROOT_DIR)/src

_BUILD_DIR = $(BUILD_DIR)/nothing
$(_BUILD_DIR):
	@mkdir -p $(BUILD_DIR) && touch $(_BUILD_DIR)

bootloader: $(_BUILD_DIR) ## Builds bootloader
	i686-elf-as $(SOURCE_DIR)/boot.s -o $(BUILD_DIR)/boot.o

kernel: $(_BUILD_DIR) ## Builds kernel
	i686-elf-gcc \
		-c $(SOURCE_DIR)/kernel.c \
		-o $(BUILD_DIR)/kernel.o \
		-std=gnu99 -ffreestanding -O2 -Wall -Wextra

build: bootloader kernel ## Link OS binary
	i686-elf-gcc -T linker.ld -o $(BUILD_DIR)/nos.bin \
		-ffreestanding -O2 -nostdlib $(BUILD_DIR)/boot.o $(BUILD_DIR)/kernel.o -lgcc

run: build
	qemu-system-i386 -kernel $(BUILD_DIR)/nos.bin

ISO_DIR = $(BUILD_DIR)/iso
iso: link ## Make ISO image
	mkdir -p $(ISO_DIR)/boot/grub
	cp $(BUILD_DIR)/nos.bin $(ISO_DIR)/boot
	cp $(ROOT_DIR)/grub.cfg $(ISO_DIR)/boot/grub
	grub-mkrescue -o $(BUILD_DIR)/nos.iso $(ISO_DIR)

help: ## Show this help
	@echo "\nSpecify a command. The choices are:\n"
	@grep -hE '^[0-9a-zA-Z_-]+:.*?## .*$$' ${MAKEFILE_LIST} \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[0;36m%-20s\033[m %s\n", $$1, $$2}'
	@echo ""
.PHONY: help

.DEFAULT_GOAL := help
