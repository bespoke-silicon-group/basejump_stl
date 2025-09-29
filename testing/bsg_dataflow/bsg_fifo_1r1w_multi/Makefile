include ../../../../bsg_cadenv/cadenv.mk

# ======================= User-configurable knobs ========================
# Path to your BaseJump STL checkout (override on cmdline or env)
BASEJUMP_STL ?= $(abspath ../../../)
$(warning $(BASEJUMP_STL))

# Top testbench module
TOP      ?= tb_bsg_fifo_1r1w_multi

# Parameters (override on 'make run', e.g., make run N=8 K=128)
N        ?= 4
K        ?= 64
LO_BITS  ?= 24
NUM_CYC  ?= 20000000
ENQ_PCT  ?= 60
DEQ_PCT  ?= 60

# Random seed for TB (+seed=<SEED>)
SEED     ?= 1

# Your RTL sources
DUT_SRCS := $(BASEJUMP_STL)/bsg_dataflow/bsg_fifo_1r1w_multi.sv
TB_SRCS  := tb.sv
VSRCS    := $(DUT_SRCS) $(TB_SRCS)

# BaseJump library search and include paths
BJS_DIRS := $(BASEJUMP_STL)/bsg_misc \
            $(BASEJUMP_STL)/bsg_mem  \
            $(BASEJUMP_STL)/bsg_dataflow

INCDIRS  := +incdir+$(BASEJUMP_STL)/bsg_misc \
            +incdir+$(BASEJUMP_STL)/bsg_mem  \
            +incdir+$(BASEJUMP_STL)/bsg_dataflow

# -y library directories plus known extensions
LIBDIRS  := $(addprefix -y ,$(BJS_DIRS)) +libext+.sv+.v

# Output / work
SIMV      := simv
LOGDIR    := logs
WORK      := work

# VCS tools
VLOGAN    ?= vlogan
VCS       ?= vcs

# Common flags
COMMON_FLAGS := -full64 -sverilog -timescale=1ns/1ps
DEBUG_FLAGS  := -debug_access+all -kdb

# Parameter overrides at elaboration time
PVALUES := \
  -pvalue+$(TOP).N=$(N) \
  -pvalue+$(TOP).K=$(K) \
  -pvalue+$(TOP).LO_BITS=$(LO_BITS) \
  -pvalue+$(TOP).NUM_CYC=$(NUM_CYC) \
  -pvalue+$(TOP).ENQ_PCT=$(ENQ_PCT) \
  -pvalue+$(TOP).DEQ_PCT=$(DEQ_PCT)

# Lint settings (vlogan supports -lint)
LINT_FLAGS := -lint=all,noVCDE,TFIPC-L

# ======================= Convenience targets ===========================
.PHONY: all build run lint gui clean help

all: run urg

$(LOGDIR):
	@mkdir -p $(LOGDIR)

# Compile (create worklib)
compile: $(LOGDIR)
	@echo "[VLOGAN] Compiling SV (worklib)"
	$(VLOGAN) $(COMMON_FLAGS) $(INCDIRS) $(LIBDIRS) $(VSRCS) -work $(WORK) -l $(LOGDIR)/vlogan.log

# Elaborate and link
build: compile
	@echo "[VCS] Elaborating top=$(TOP) N=$(N) K=$(K)"
	$(VCS) $(COMMON_FLAGS) $(DEBUG_FLAGS) -top $(TOP) $(PVALUES) -o $(SIMV) -l $(LOGDIR)/vcs.log

run: build
	@echo "[RUN] ./$(SIMV) +seed=$(SEED)"
	./$(SIMV) +seed=$(SEED) | tee $@.log

urg:
	$(SYNOPSYS)/vcs/U-2023.03-SP1/bin/urg -full64 -dir simv.vdb -format both -report covreport
	google-chrome file:$$PWD/covreport/dashboard.html

# Lint (syntax/semantic)
lint: $(LOGDIR)
	@echo "[VLOGAN] Linting"
	$(VLOGAN) $(COMMON_FLAGS) $(INCDIRS) $(LIBDIRS) $(VSRCS) $(LINT_FLAGS) -work $(WORK) -l $(LOGDIR)/lint.log

# Launch DVE GUI (post-build)
gui: build
	@echo "[GUI] ./$(SIMV) -gui"
	./$(SIMV) -gui &

clean:
	@echo "[CLEAN]"
	rm -rf $(SIMV) simv.daidir csrc DVEfiles *.vcd *.vpd ucli.key \
	       $(WORK) $(LOGDIR)

help:
	@echo "Targets:"
	@echo "  make run            # compile, elaborate, and run"
	@echo "  make build          # compile + elaborate, no run"
	@echo "  make lint           # vlogan lint"
	@echo "  make gui            # run with DVE GUI"
	@echo "  make clean"
	@echo ""
	@echo "Knobs (override on cmdline):"
	@echo "  BASEJUMP_STL=<path>  (default: ../basejump_stl)"
	@echo "  N=<fifos> K=<pool> SEED=<int> LO_BITS=<bits> NUM_CYC=<cycles> ENQ_PCT=<pct> DEQ_PCT=<pct>"
	@echo ""
	@echo "Examples:"
	@echo "  make run N=8 K=128 SEED=42"
	@echo "  make gui N=2 K=16"
