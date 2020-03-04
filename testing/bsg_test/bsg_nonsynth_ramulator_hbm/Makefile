export BSG_CADENV_DIR = $(abspath ../../../../bsg_cadenv)
export BASEJUMP_STL_DIR = $(abspath ../../..)
include $(BSG_CADENV_DIR)/cadenv.mk

INCDIR += +incdir+$(BASEJUMP_STL_DIR)/bsg_misc

CFLAGS += -CFLAGS "-std=c++11 -g -Wall"
CFLAGS += -CFLAGS "-fPIC"
CFLAGS += -CFLAGS "-I$(BASEJUMP_STL_DIR)/imports/ramulator/src"
CFLAGS += -CFLAGS "-DRAMULATOR"
CFLAGS += -CFLAGS "-DHBM_CONFIG_PATH=$(BASEJUMP_STL_DIR)/imports/ramulator/configs/HBM-config.cfg"

all: sim

trace_0.tr: hbm_trace_gen.py
	python hbm_trace_gen.py > $@

sim: trace_0.tr
	vcs -R +v2k +lint=all,noSVA-UA,noSVA-NSVU,noVCDE \
		-cpp clang++ $(CFLAGS) \
		$(INCDIR) \
		-sverilog -full64 -f sv.include -timescale=1ps/1ps +vcs+vcdpluson -l vcs.log
		

dve:
	dve -full64 -vpd vcdplus.vpd &

clean:
	rm -f simv vcs.log vcdplus.vpd vc_hdrs.h ucli.key
	rm -rf csrc simv.daidir DVEfiles
	rm -rf stack.info.*
	rm -f trace_0.tr
	rm -f HBM.stats ramulator_access_trace.txt
