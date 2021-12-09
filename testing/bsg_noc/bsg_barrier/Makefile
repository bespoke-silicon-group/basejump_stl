include ../../../../bsg_cadenv/cadenv.mk
export BASEJUMP_STL_DIR = $(abspath ../../..)

INCDIR = +incdir+$(BASEJUMP_STL_DIR)/bsg_misc

.PHONY: run dve clean
run:
	$(VCS) +v2k -R +lint=all,noSVA-UA,noSVA-NSVU,noVCDE \
		-sverilog -full64 -assert svaext -f filelist $(INCDIR) \
		-timescale=1ps/1ps -debug_pp +vcs+vcdpluson -l vcs.log

dve:
	$(DVE) -full64 -vpd vcdplus.vpd &


clean:
	rm -rf csrc DVEfiles simv simv.daidir ucli.key vcdplus.vpd vc_hdrs.h vcs.log
