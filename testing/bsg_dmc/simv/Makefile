# Workspace directory
# TODO: akashs3- bad exports below. Make a common makefile with ROOT_PATH for all TBs in the basejump_stl/testing area and derive path from there. 
export BASEJUMP_STL_DIR = ../../..
export BSG_CADENV_DIR = $(BASEJUMP_STL_DIR)/../bsg_cadenv

# Environment
include $(BSG_CADENV_DIR)/cadenv.mk

export VCS_HOME = $(VCS_RELEASE)

ELABORATE_OPTIONS = -full64
ELABORATE_OPTIONS += -sverilog
ELABORATE_OPTIONS += -debug_all
ELABORATE_OPTIONS += -lca
ELABORATE_OPTIONS += +vcs+vcdpluson
ELABORATE_OPTIONS += +vcs+vcdplusmemon
ELABORATE_OPTIONS += -timescale=1ns/100ps
ELABORATE_OPTIONS += -assert svaext
#TODO: akashs3 randomise the BFM to be fetched over time for below define.
ELABORATE_OPTIONS += +define+den2048Mb+sg75+x16+FULL_MEM

ifdef coverage
	ELABORATE_OPTIONS += -cm line+cond+fsm+tgl -cm path
	DVE_OPTIONS += -cov -dir consecutive_writes.vdb -dir rand_cov.vdb 
endif

ifdef scenario
		RUN_OPTIONS += +scenario=$(scenario)
endif

ifdef addr
		RUN_OPTIONS += +addr=$(addr)
endif

ifdef read_write_iter
		RUN_OPTIONS += +read_write_iter=$(read_write_iter)
endif

ifdef ntb_random_seed
		RUN_OPTIONS += +ntb_random_seed=$(ntb_random_seed)
endif

ifndef coverage
	ifdef vpd
		DVE_OPTIONS += -vpd $(vpd)
	else
		DVE_OPTIONS+= -vpd vcdplus.vpd
	endif
endif

elaborate: 
	$(VCS_BIN)/vcs $(ELABORATE_OPTIONS) -f filelist.lst -l $@.log $(BASEJUMP_STL_DIR)/testing/bsg_dmc/tb_top/testbench.sv
	touch $@

run:
	./simv $(RUN_OPTIONS) -l $@.log 
	touch $@

dve:
	$(VCS_BIN)/dve -full64 $(DVE_OPTIONS) &

clean:
	rm elaborate run
	rm -rf *.log
	rm -rf elaborate_*
	rm -rf simv*
	rm -rf csrc
	rm -rf ucli.key
	rm -rf AN.DB
	rm vc_hdrs.h
