# Workspace directory
# TODO: akashs3- bad exports below. Make a common makefile with ROOT_PATH for all TBs in the basejump_stl/testing area and derive path from there. 
export BASEJUMP_STL_DIR = ../../..
export BSG_CADENV_DIR = $(BASEJUMP_STL_DIR)/../bsg_cadenv

# Environment
include $(BSG_CADENV_DIR)/cadenv.mk

#TODO akashs3 commented: Why is this needed?
#ANALYSIS_OPTIONS = -full64
#ANALYSIS_OPTIONS += -sverilog
#ANALYSIS_OPTIONS += +incdir+../../bsg_clk_gen
#ANALYSIS_OPTIONS += +incdir+../../bsg_misc

ELABORATE_OPTIONS = -full64
ELABORATE_OPTIONS += -sverilog
ELABORATE_OPTIONS += -debug_pp
ELABORATE_OPTIONS += -lca
ELABORATE_OPTIONS += +vcs+vcdpluson
ELABORATE_OPTIONS += +vcs+vcdplusmemon
ELABORATE_OPTIONS += -timescale=1ps/1ps
ELABORATE_OPTIONS += -assert svaext
#TODO: akashs3 randomise the BFM to be fetched over time for below define.
ELABORATE_OPTIONS += +define+den2048Mb+sg5+x16+FULL_MEM
RUN_OPTIONS = 

#TODO akashs3 commented: Why is this needed?
#analyze:
#	$(VCS_BIN)/vlogan $(ANALYSIS_OPTIONS) -timescale=1ns/1ps +incdir+lpddr_verilog_model+../../bsg_dmc +define+den2048Mb+sg5+x16+FULL_MEM -f filelist.lst -l  $@.log
#	touch $@

elaborate: 
	$(VCS_BIN)/vcs $(ELABORATE_OPTIONS) -f filelist.lst -l $@.log $(BASEJUMP_STL_DIR)/testing/bsg_dmc/tb_top/testbench.v
	touch $@

run: elaborate
	./simv $(RUN_OPTIONS) -l $@.log
	touch $@

dve: run
	$(VCS_BIN)/dve -full64 -vpd vcdplus.vpd &

clean:
	rm analyze elaborate run
	rm -rf *.log
	rm -rf analyze_*
	rm -rf *.vpd
	rm -rf simv*
	rm -rf csrc
	rm -rf ucli.key
	rm -rf DVEfiles
	rm -rf AN.DB
