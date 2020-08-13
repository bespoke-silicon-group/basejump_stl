
# Workspace directory
export TOP_DIR = $(abspath .)
export BSG_CADENV_DIR = $(TOP_DIR)/../../../../bsg_cadenv
export BASEJUMP_STL_DIR = $(TOP_DIR)/../../..

# Environment
include $(BSG_CADENV_DIR)/cadenv.mk

FAST_TO_SLOWS := 0 1
UTILIZATIONS := 10 20 30 40 50 60 70 80 90 99

RUNS := $(foreach FAST_TO_SLOW_P, $(FAST_TO_SLOWS), \
            $(foreach UTILIZATION_P, $(UTILIZATIONS), \
                run-$(FAST_TO_SLOW_P)-$(UTILIZATION_P)))

run: $(RUNS)
run-%:
	mkdir run-$*;
	cd run-$* && \
        $(VCS_BIN)/vcs -full64 -sverilog -timescale=1ps/1ps -f $(TOP_DIR)/filelist -debug_pp -R -top bsg_noc_performance_tester +vcs+vcdpluson \
        -pvalue+top_is_fast_to_slow_p=$(word 1, $(subst -, ,$*)) \
        -pvalue+top_utilization_p=$(word 2, $(subst -, ,$*)) \
        > run-$*.log

view-%:
	cd run-$* && \
        $(VCS_BIN)/dve -full64 -vpd vcdplus.vpd &

junk = csrc DVEfiles simv.daidir *.old *.vpd simv *.key run-*

clean:
	rm -rf $(junk)

