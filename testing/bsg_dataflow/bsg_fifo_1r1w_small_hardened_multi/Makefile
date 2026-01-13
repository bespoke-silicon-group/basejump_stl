include ../../../../bsg_cadenv/cadenv.mk

# ======================= User-configurable knobs ========================
BASEJUMP_STL ?= $(abspath ../../../)
$(warning $(BASEJUMP_STL))

TOP      ?= tb_bsg_fifo_1r1w_small_hardened_multi

WIDTH    ?= 32
ELS      ?= 4
FIFOS    ?= 4
NUM_CYC  ?= 200000
ENQ_PCT  ?= 60
DEQ_PCT  ?= 60

SEED     ?= 1

DUT_SRCS := $(BASEJUMP_STL)/bsg_dataflow/bsg_fifo_1r1w_small_hardened_multi.sv
TB_SRCS  := tb.sv
VSRCS    := $(DUT_SRCS) $(TB_SRCS)

BJS_DIRS := $(BASEJUMP_STL)/bsg_misc \
            $(BASEJUMP_STL)/bsg_mem  \
            $(BASEJUMP_STL)/bsg_dataflow

INCDIRS  := +incdir+$(BASEJUMP_STL)/bsg_misc \
            +incdir+$(BASEJUMP_STL)/bsg_mem  \
            +incdir+$(BASEJUMP_STL)/bsg_dataflow

LIBDIRS  := $(addprefix -y ,$(BJS_DIRS)) +libext+.sv+.v

SIMV      := simv
LOGDIR    := logs
WORK      := work

VLOGAN    ?= vlogan
VCS       ?= vcs

COMMON_FLAGS := -full64 -sverilog -timescale=1ns/1ps
DEBUG_FLAGS  := -debug_access+all -kdb

PVALUES := \
  -pvalue+$(TOP).WIDTH=$(WIDTH) \
  -pvalue+$(TOP).ELS=$(ELS) \
  -pvalue+$(TOP).FIFOS=$(FIFOS) \
  -pvalue+$(TOP).NUM_CYC=$(NUM_CYC) \
  -pvalue+$(TOP).ENQ_PCT=$(ENQ_PCT) \
  -pvalue+$(TOP).DEQ_PCT=$(DEQ_PCT)

LINT_FLAGS := -lint=all,noVCDE,TFIPC-L

.PHONY: all build run lint gui clean help

all: run

$(LOGDIR):
	@mkdir -p $(LOGDIR)

compile: $(LOGDIR)
	@echo "[VLOGAN] Compiling SV (worklib)"
	$(VLOGAN) $(COMMON_FLAGS) $(INCDIRS) $(LIBDIRS) $(VSRCS) -work $(WORK) -l $(LOGDIR)/vlogan.log

build: compile
	@echo "[VCS] Elaborating top=$(TOP)"
	$(VCS) $(COMMON_FLAGS) $(DEBUG_FLAGS) -top $(TOP) $(PVALUES) -o $(SIMV) -l $(LOGDIR)/vcs.log

run: build
	@echo "[RUN] ./$(SIMV) +seed=$(SEED)"
	./$(SIMV) +seed=$(SEED) | tee $@.log

lint: $(LOGDIR)
	@echo "[VLOGAN] Linting"
	$(VLOGAN) $(COMMON_FLAGS) $(INCDIRS) $(LIBDIRS) $(VSRCS) $(LINT_FLAGS) -work $(WORK) -l $(LOGDIR)/lint.log

gui: build
	@echo "[GUI] ./$(SIMV) -gui"
	./$(SIMV) -gui &

clean:
	@echo "[CLEAN]"
	rm -rf $(SIMV) simv.daidir csrc DVEfiles *.vcd *.vpd ucli.key \
	       $(WORK) $(LOGDIR)

help:
	@echo "Targets:"
	@echo "  make run"
	@echo "  make build"
	@echo "  make lint"
	@echo "  make gui"
	@echo "  make clean"
	@echo ""
	@echo "Knobs (override on cmdline):"
	@echo "  WIDTH=<bits> ELS=<depth> FIFOS=<count> NUM_CYC=<cycles>"
	@echo "  ENQ_PCT=<pct> DEQ_PCT=<pct> SEED=<int>"
	@echo ""
	@echo "Examples:"
	@echo "  make run FIFOS=8 ELS=8 SEED=42"
