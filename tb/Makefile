.ONESHELL:

REPO_ROOT := $(abspath ..)
ASM_DIR := $(REPO_ROOT)/tests/asm
RTL_DIR := $(REPO_ROOT)/rtl
TB_DIR := $(REPO_ROOT)/tb
TRACE_DIR := $(REPO_ROOT)/traces
SIM := $(TB_DIR)/a.out
DEBUG ?= 0

ASM_SRCS := $(wildcard $(ASM_DIR)/*.asm)
NUMBERED_ASM_SRCS := $(wildcard $(ASM_DIR)/[0-9]*.asm)
TESTS := $(basename $(notdir $(NUMBERED_ASM_SRCS)))

.PHONY: all build assemble run run-all clean

all: run-all

build:
	iverilog -P hart_tb.DEBUG=$(DEBUG) -o $(SIM) $(TB_DIR)/tb.v $(RTL_DIR)/*.v

assemble:
	test -n "$(PROGRAM)"
	docker run --rm -v $(REPO_ROOT):/src coderkalyan/ece552-tools:latest bash -c "\
		cd /src/tests/asm && \
		riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 $(PROGRAM).asm -o $(PROGRAM).o && \
		riscv64-unknown-elf-objcopy -O binary -j .text --pad-to=0x400 $(PROGRAM).o $(PROGRAM).hex \
	"
	xxd -g 1 -c 4 -p $(ASM_DIR)/$(PROGRAM).hex | sed 's/../& /g' > $(TB_DIR)/program.mem

run: build assemble
	mkdir -p $(TRACE_DIR)
	cd $(TB_DIR)
	trace_name=$${PROGRAM:-program}
	vvp ./a.out > $(TRACE_DIR)/$${trace_name}.trace 2>&1
	if grep -q "Program halted after" $(TRACE_DIR)/$${trace_name}.trace; then \
		last_w10=$$(grep "w\[10\]=" $(TRACE_DIR)/$${trace_name}.trace | tail -n 1 | sed 's/.*w\[10\]=\([0-9a-fA-F]*\).*/\1/'); \
		if [ "$$last_w10" = "00000001" ]; then \
			echo "[PASS] $${trace_name} completed successfully (x10=1)."; \
		else \
			echo "[FAIL] $${trace_name} failed. Final x10=0x$${last_w10}. Check $(TRACE_DIR)/$${trace_name}.trace"; \
			exit 1; \
		fi; \
	else \
		echo "[FAIL] $${trace_name} did not halt correctly (timeout/crash). Check $(TRACE_DIR)/$${trace_name}.trace"; \
		exit 1; \
	fi

run-%:
	$(MAKE) run PROGRAM=$*

run-all: build
	for t in $(TESTS); do \
		echo "========== Running $$t =========="; \
		$(MAKE) --no-print-directory run PROGRAM=$$t || exit $$?; \
	done

clean:
	rm -f $(SIM) $(TB_DIR)/program.mem
	rm -f $(ASM_DIR)/*.o $(ASM_DIR)/*.hex
	rm -f $(TRACE_DIR)/*.trace $(TB_DIR)/hart.vcd
