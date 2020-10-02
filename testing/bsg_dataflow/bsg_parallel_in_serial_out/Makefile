
# Workspace directory
export TOP_DIR = $(abspath .)
export BSG_CADENV_DIR = $(TOP_DIR)/../../../../bsg_cadenv
export BASEJUMP_STL_DIR = $(TOP_DIR)/../../..

# Environment
include $(BSG_CADENV_DIR)/cadenv.mk

CLK_SPEEDS := 41-5-5 20-5-5 10-5-5 7-5-5 5-5-5 3-5-5 5-5-7 5-5-3
RATIOS := 4 2 1
HI_TO_LOS := 0 1
MIN_BUFFERINGS := 0 1

RUNS := $(foreach CLK_SPEED_P, $(CLK_SPEEDS), \
            $(foreach RATIO_P, $(RATIOS), \
                $(foreach HI_TO_LO_P, $(HI_TO_LOS), \
                    $(foreach MIN_BUFFERING_P, $(MIN_BUFFERINGS), \
                        run-$(CLK_SPEED_P)-$(RATIO_P)-$(HI_TO_LO_P)-$(MIN_BUFFERING_P)))))

run: $(RUNS)
run-%:
	mkdir run-$*;
	cd run-$* && \
        $(VCS_BIN)/vcs -full64 -sverilog -timescale=1ps/1ps -f $(TOP_DIR)/filelist -debug_pp -R -top bsg_parallel_in_serial_out_tester +vcs+vcdpluson \
        -pvalue+top_master_clk_period_p=$(word 1, $(subst -, ,$*)) \
        -pvalue+top_piso_clk_period_p=$(word 2, $(subst -, ,$*)) \
        -pvalue+top_client_clk_period_p=$(word 3, $(subst -, ,$*)) \
        -pvalue+top_els_p=$(word 4, $(subst -, ,$*)) \
        -pvalue+top_hi_to_lo_p=$(word 5, $(subst -, ,$*)) \
        -pvalue+top_use_minimal_buffering_p=$(word 6, $(subst -, ,$*)) \
        > run-$*.log

view-%:
	cd run-$* && \
        $(VCS_BIN)/dve -full64 -vpd vcdplus.vpd &

junk = csrc DVEfiles simv.daidir *.old *.vpd simv *.key run-*

clean:
	rm -rf $(junk)

