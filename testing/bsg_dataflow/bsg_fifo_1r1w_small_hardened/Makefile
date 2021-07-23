
# Workspace directory
export TOP_DIR = $(abspath .)
export BSG_CADENV_DIR = $(TOP_DIR)/../../../../bsg_cadenv
export BASEJUMP_STL_DIR = $(TOP_DIR)/../../..

# Environment
include $(BSG_CADENV_DIR)/cadenv.mk

PERIODS := 2 3 5 7 11
CLK_SPEEDS := $(foreach MASTER, $(PERIODS), \
                  $(foreach FIFO, $(PERIODS), \
                      $(foreach CLIENT, $(PERIODS), \
                          $(MASTER)-$(FIFO)-$(CLIENT))))

RUNS := $(foreach CLK_SPEED_P, $(CLK_SPEEDS), \
            run-$(CLK_SPEED_P))

run: $(RUNS)
run-%:
	mkdir run-$*;
	cd run-$* && \
        $(VCS_BIN)/vcs -full64 -sverilog -timescale=1ps/1ps -f $(TOP_DIR)/filelist -debug_pp -R -top bsg_fifo_1r1w_small_hardened_tester +vcs+vcdpluson -assert svaext +vcs+lic+wait \
        -pvalue+top_master_clk_period_p=$(word 1, $(subst -, ,$*)) \
        -pvalue+top_piso_clk_period_p=$(word 2, $(subst -, ,$*)) \
        -pvalue+top_client_clk_period_p=$(word 3, $(subst -, ,$*)) \
        > run-$*.log

view-%:
	cd run-$* && \
        $(VCS_BIN)/dve -full64 -vpd vcdplus.vpd &

check:
	@echo 'Number of tests passed:'
	@grep -r PASS */*.log | wc -l
	@echo 'Number of tests failed:'
	@grep -r FAIL */*.log | wc -l

junk = csrc DVEfiles simv.daidir *.old *.vpd simv *.key vc_hdrs.h run-*

clean:
	rm -rf $(junk)

