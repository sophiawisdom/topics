# A simple build script for building projects.
#
# usage: make [CONFIG=debug|release]

MODULE_NAME = topics
SDK         = macosx
ARCH        = x86_64

CONFIG     ?= debug

ROOT_DIR    = $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
OUTPUT_DIR  = $(ROOT_DIR)
TARGET_DIR  = $(OUTPUT_DIR)
SRC_DIR     = $(ROOT_DIR)/src

ifeq ($(CONFIG), debug)
    CFLAGS=-Onone -g
else
    CFLAGS=-O3
endif

SWIFTC      = $(shell xcrun -f swiftc)
CLANG       = $(shell xcrun -f clang)
SDK_PATH    = $(shell xcrun --show-sdk-path --sdk $(SDK))
SWIFT_FILES = $(wildcard $(SRC_DIR)/*.swift)

build:
	mkdir -p $(TARGET_DIR)
	$(SWIFTC) $(SWIFT_FILES) -emit-executable -sdk $(SDK_PATH) -o $(ROOT_DIR)/$(MODULE_NAME)

clean:
	rm -rf $(TARGET_DIR)

nuke:
	rm -rf $(OUTPUT_DIR)
