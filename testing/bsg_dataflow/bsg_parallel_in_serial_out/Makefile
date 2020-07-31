
# Workspace directory
dir = ../../../..

export BSG_CADENV_DIR = $(dir)/bsg_cadenv
export BASEJUMP_STL_DIR = ../../..

# Environment
include $(BSG_CADENV_DIR)/cadenv.mk

CLK_SPEEDS := 41-5-5 20-5-5 10-5-5 7-5-5 5-5-5 3-5-5 5-5-7 5-5-5 5-5-3
RATIOS := 4 2 1
MIN_BUFFERINGS := 0 1

run:
	$(VCS_BIN)/vcs -full64 -sverilog -timescale=1ps/1ps -f ./filelist -debug_pp -R -top bsg_parallel_in_serial_out_tester +vcs+vcdpluson \
        -pvalue+top_master_clk_period_p=5 \
        -pvalue+top_piso_clk_period_p=5 \
        -pvalue+top_client_clk_period_p=5 \
        -pvalue+top_els_p=4 \
        -pvalue+top_hi_to_lo_p=0 \
        -pvalue+top_use_minimal_buffering_p=0

view:
	$(VCS_BIN)/dve -full64 -vpd vcdplus.vpd &

junk = csrc DVEfiles simv.daidir *.old *.vpd simv *.key *.log

clean:
	rm -rf $(junk)

