
# Workspace directory
export TOP_DIR = $(abspath .)
export BSG_CADENV_DIR = $(TOP_DIR)/../../../../bsg_cadenv
export BASEJUMP_STL_DIR = $(TOP_DIR)/../../..

# Environment
include $(BSG_CADENV_DIR)/cadenv.mk

run:
	$(VCS_BIN)/vcs -full64 -sverilog -timescale=1ps/1ps -f $(TOP_DIR)/filelist -debug_pp -R -top bsg_fifo_1r1w_small_hardened_tester +vcs+vcdpluson -assert svaext +vcs+lic+wait -cm line+fsm+branch+cond+tgl

run-one-clock:
	$(VCS_BIN)/vcs -full64 -sverilog -timescale=1ps/1ps -f $(TOP_DIR)/filelist -debug_pp -R -top bsg_fifo_1r1w_small_hardened_tester +vcs+vcdpluson -assert svaext +vcs+lic+wait -cm line+fsm+branch+cond+tgl -pvalue+top_num_clocks_p=1

view:
	$(VCS_BIN)/dve -full64 -vpd vcdplus.vpd &

cov:
	$(VCS_BIN)/dve -full64 -cov -covdir simv.vdb &

junk = csrc DVEfiles simv.daidir *.old *.vpd simv *.key vc_hdrs.h cm.log simv.vdb

clean:
	rm -rf $(junk)

