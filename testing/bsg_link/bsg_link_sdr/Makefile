

# Workspace directory
export BASEJUMP_STL_DIR = ../../..
export BSG_CADENV_DIR = $(BASEJUMP_STL_DIR)/../bsg_cadenv

# Environment
include $(BSG_CADENV_DIR)/cadenv.mk

run:
	$(VCS_BIN)/vcs -full64 -sverilog -timescale=1ps/1ps -f ./filelist -debug_pp -R -top bsg_link_sdr_tester +vcs+vcdpluson -assert svaext

view:
	$(VCS_BIN)/dve -full64 -vpd vcdplus.vpd &

junk = csrc DVEfiles simv.daidir *.old *.vpd simv *.key vc_hdrs.h

clean:
	rm -rf $(junk)

