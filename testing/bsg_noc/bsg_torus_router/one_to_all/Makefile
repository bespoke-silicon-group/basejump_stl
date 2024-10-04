export BASEJUMP_STL_DIR = $(shell git rev-parse --show-toplevel)
export BSG_CADENV_DIR = $(abspath $(BASEJUMP_STL_DIR)/../bsg_cadenv)
include $(BSG_CADENV_DIR)/cadenv.mk


VCS_INCDIR = +incdir+$(BASEJUMP_STL_DIR)/bsg_misc
VCS_INCDIR += +incdir+$(BASEJUMP_STL_DIR)/bsg_noc

VCS_DEFINE =

run:
	vcs -R +v2k -sverilog -full64 -f sv.filelist -l vcs.log $(VCS_DEFINE)\
  	-debug_pp -timescale=1ps/1ps +vcs+vcdpluson -top testbench -reportstats \
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

