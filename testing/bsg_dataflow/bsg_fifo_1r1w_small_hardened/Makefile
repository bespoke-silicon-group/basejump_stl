
# Workspace directory
dir = ../../../..

export BSG_CADENV_DIR = $(dir)/bsg_cadenv
export BASEJUMP_STL_DIR = ../../..

# Environment
include $(BSG_CADENV_DIR)/cadenv.mk

run:
	$(VCS_BIN)/vcs -full64 -sverilog -timescale=1ps/1ps -f ./filelist -debug_pp -R -top bsg_fifo_1r1w_small_hardened_tester +vcs+vcdpluson
    
view:
	$(VCS_BIN)/dve -full64 -vpd vcdplus.vpd &

junk = csrc DVEfiles simv.daidir *.old *.vpd simv *.key

clean:
	rm -rf $(junk)

