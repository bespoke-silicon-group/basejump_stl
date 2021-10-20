export BASEJUMP_STL_DIR = $(shell git rev-parse --show-toplevel)
export BSG_CADENV_DIR = $(abspath $(BASEJUMP_STL_DIR)/../bsg_cadenv)
include $(BSG_CADENV_DIR)/cadenv.mk


VCS_INCDIR = +incdir+$(BASEJUMP_STL_DIR)/bsg_misc

run:
	vcs -R +v2k -sverilog -full64 -f filelist -l vcs.log \
		-debug_pp -timescale=1ps/1ps +vcs+vcdpluson \
		+lint=all,noSVA-UA,noSVA-NSVU,noVCDE,noNS  -assert svaext \
		-cm line+fsm+branch+cond+tgl \
		$(VCS_INCDIR)

dve:
	dve -full64 -vpd vcdplus.vpd &

cov:
	dve -full64 -cov -covdir simv.vdb &

clean:
	rm -rf DVEfiles
	rm -rf csrc
	rm -rf simv.daidir simv.vdb
	rm -f ucli.key vcdplus.vpd simv *.tar.gz
	rm -f simv.log vcs.log vc_hdrs.h
	rm -f cm.log
