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

DRAMS := hbm2_8gb_x128 hbm2_4gb_x128

all: $(DRAMS)

$(DRAMS): %: %.tr
$(DRAMS):
	vcs -R +v2k +lint=all,noSVA-UA,noSVA-NSVU,noVCDE \
		-cpp g++ $(CFLAGS) \
		$(INCDIR) \
		+define+dram_pkg=bsg_dramsim3_$@_pkg \
		+define+trace_file=$@.trace \
		+define+rom_file=$@.tr \
		-sverilog -full64 -f sv.include -timescale=1ps/1ps +vcs+vcdpluson -l vcs.log

$(foreach dram, $(DRAMS), $(dram).tr):
	python hbm_trace_gen.py $(@:.tr=) > $@

dve:
	dve -full64 -vpd vcdplus.vpd &

clean:
	rm -f simv vcs.log vcdplus.vpd vc_hdrs.h ucli.key
	rm -rf csrc simv.daidir DVEfiles
	rm -rf stack.info.*
	rm -f *.tr
	rm -f *.trace
	rm -f *~
