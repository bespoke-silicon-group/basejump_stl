export BSG_CADENV_DIR = $(abspath ../../../../bsg_cadenv)
export BASEJUMP_STL_DIR = $(abspath ../../..)
include $(BSG_CADENV_DIR)/cadenv.mk

INCDIR += +incdir+$(BASEJUMP_STL_DIR)/bsg_misc
INCDIR += +incdir+$(BASEJUMP_STL_DIR)/bsg_test

CFLAGS += -CFLAGS "-std=c++11 -g -Wall"
CFLAGS += -CFLAGS "-fPIC"
CFLAGS += -CFLAGS "-I$(BASEJUMP_STL_DIR)/imports/DRAMSim3/src"
CFLAGS += -CFLAGS "-I$(BASEJUMP_STL_DIR)/imports/DRAMSim3/ext/headers"
CFLAGS += -CFLAGS "-I$(BASEJUMP_STL_DIR)/imports/DRAMSim3/ext/fmt/include"
CFLAGS += -CFLAGS "-DFMT_HEADER_ONLY=1"
CFLAGS += -CFLAGS "-DBASEJUMP_STL_DIR=$(BASEJUMP_STL_DIR)"

all: sim

trace_0.tr: hbm_trace_gen.py
	python hbm_trace_gen.py > $@

sim: trace_0.tr
sim:
	vcs -R +v2k +lint=all,noSVA-UA,noSVA-NSVU,noVCDE \
		-cpp g++ $(CFLAGS) \
		$(INCDIR) \
		-sverilog -full64 -f sv.include -timescale=1ps/1ps +vcs+vcdpluson -l vcs.log


dve:
	dve -full64 -vpd vcdplus.vpd &

clean:
	rm -f simv vcs.log vcdplus.vpd vc_hdrs.h ucli.key
	rm -rf csrc simv.daidir DVEfiles
	rm -rf stack.info.*
	rm -f trace_0.tr
	rm -f bsg_nonsynth_dramsim3_*_trace.txt
	rm -f *~
	rm -f HBM.stats
