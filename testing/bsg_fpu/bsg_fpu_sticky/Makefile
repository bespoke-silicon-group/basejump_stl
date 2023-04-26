TOP ?= $(shell git rev-parse --show-toplevel)
BSG_CADENV_DIR ?= $(TOP)/../bsg_cadenv

include $(BSG_CADENV_DIR)/cadenv.mk

run:
	vcs -f sv.include +incdir+$(TOP)/bsg_misc +v2k -R +lint=all -sverilog -full64 \
		-debug_pp -timescale=1ns/10ps -l sim.log

dve:
	dve -full64 -vpd vcdplus.vpd &

clean:
	rm -r -f DVEfiles
	rm -r -f csrc
	rm -f sim.log
	rm simv
	rm -r -f simv.daidir 
	rm -f ucli.key
	rm -f vcdplus.vpd
