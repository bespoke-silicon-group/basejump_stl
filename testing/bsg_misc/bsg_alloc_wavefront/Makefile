export THIS_DIR = $(abspath .)
export BASEJUMP_STL_DIR = $(shell git rev-parse --show-toplevel)
export CADENV_DIR = $(abspath $(BASEJUMP_STL_DIR)/../bsg_cadenv)

include $(CADENV_DIR)/cadenv.mk

VCS_FLAGS 	+= -R -full64 +v2k -sverilog
VCS_FLAGS 	+= -timescale=1ps/1ps
VCS_FLAGS 	+= +lint=all,noSVA-UA,noSVA-NSVU,noVCDE,noNS -top testbench
VCS_FLAGS 	+= -licqueue
VCS_FLAGS 	+= -reportstats
VCS_FLAGS 	+= -assert svaext
VCS_FLAGS 	+= -l run.log
VCS_FLAGS 	+= -debug_pp
VCS_FLAGS 	+= +vcs+vcdpluson
#VCS_FLAGS 	+= +vcs+nostdout

VCS_INCDIR 	+= +incdir+$(BASEJUMP_STL_DIR)/bsg_misc

VCS_DEFINES += 

run:
	vcs -R -full64 $(VCS_FLAGS) $(VCS_INCDIR) $(VCS_DEFINES) -f  sv.filelist


dve:
	dve -full64 -vpd vcdplus.vpd &


clean:
	rm -rf csrc simv simv.daidir stack.info*
	rm -rf ucli.key vc_hdrs.h vcdplus.vpd run.log
