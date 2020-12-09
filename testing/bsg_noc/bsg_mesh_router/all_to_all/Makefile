export BASEJUMP_STL_DIR = $(shell git rev-parse --show-toplevel)
export BSG_CADENV_DIR = $(abspath $(BASEJUMP_STL_DIR)/../bsg_cadenv)
include $(BSG_CADENV_DIR)/cadenv.mk



VCS_INCDIR = +incdir+$(BASEJUMP_STL_DIR)/bsg_misc
VCS_INCDIR += +incdir+$(BASEJUMP_STL_DIR)/bsg_noc

NUM_X    ?= 16
NUM_Y    ?= 8
XY_ORDER ?= 1
DIMS_P   ?= 2
RUCHE_X  ?= 0
RUCHE_Y  ?= 0


VCS_DEFINE =  +define+NUM_X=${NUM_X}
VCS_DEFINE += +define+NUM_Y=${NUM_Y}
VCS_DEFINE += +define+XY_ORDER=${XY_ORDER}
VCS_DEFINE += +define+DIMS_P=${DIMS_P}
VCS_DEFINE += +define+RUCHE_X=${RUCHE_X}
VCS_DEFINE += +define+RUCHE_Y=${RUCHE_Y}

run:
	vcs -R +v2k -sverilog -full64 -f sv.include -l vcs.log $(VCS_DEFINE)\
		-debug_pp -timescale=1ps/1ps +vcs+vcdpluson	-top testbench -reportstats \
		+lint=all,noSVA-UA,noSVA-NSVU,noVCDE,noNS \
		$(VCS_INCDIR) \
		$(VCS_DEFINE)


dve:
	dve -full64 -vpd vcdplus.vpd &

clean:
	rm -rf DVEfiles
	rm -rf csrc
	rm -rf simv.daidir simv.vdb
	rm -f ucli.key vcdplus.vpd simv *.tar.gz
	rm -f simv.log vcs.log
