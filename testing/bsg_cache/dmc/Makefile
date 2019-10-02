include ../../../../bsg_cadenv/cadenv.mk
export BASEJUMP_STL_DIR=../../..

NUM_CACHE_P = 4
WAYS_P ?= 2 

INCDIR = +incdir+$(BASEJUMP_STL_DIR)/bsg_misc
INCDIR += +incdir+$(BASEJUMP_STL_DIR)/testing/bsg_dmc/lpddr_verilog_model

DEFINE = +define+WAYS_P=$(WAYS_P)

DDR_PARAM = +define+den2048Mb+sg5+x16+FULL_MEM

NUMS = $(shell seq 0 `expr $(NUM_CACHE_P) - 1`)
BASE = bsg_trace_rom_
TRACE_ROMS = $(addsuffix .v, $(addprefix $(BASE), $(NUMS)))

all: sim

bsg_trace_rom_%.tr:
	python dmc_trace_gen.py $* $(WAYS_P) > $@

bsg_trace_rom_%.v: bsg_trace_rom_%.tr
	python $(BASEJUMP_STL_DIR)/bsg_mem/bsg_ascii_to_rom.py $< bsg_trace_rom_$* > $@

sim: $(TRACE_ROMS)
	vcs +v2k -R +lint=all,noSVA-UA,noSVA-NSVU,noVCDE -sverilog -full64 \
		$(INCDIR) $(DDR_PARAM) -f sv.include $(TRACE_ROMS) $(DEFINE) \
		-timescale=1ps/1ps +vcs+vcdpluson -l vcs.log

dve:
	dve -full64 -vpd vcdplus.vpd &


clean:
	rm -f simv
	rm -rf simv.daidir csrc stack.info.* DVEfiles
	rm -f vcs.log vcdplus.vpd ucli.key
	rm -f $(TRACE_ROMS) *.tr
