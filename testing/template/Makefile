#
#		Makefile
#
export BASEJUMP_STL_DIR = $(shell git rev-parse --show-toplevel)
export BSG_CADENV_DIR = $(abspath $(BASEJUMP_STL_DIR)/../bsg_cadenv)
include $(BSG_CADENV_DIR)/cadenv.mk

# include path
VCS_INCDIR = +incdir+$(BASEJUMP_STL_DIR)/bsg_misc

# pass define macro like this for compile-time parameters.
VCS_DEFINE = +define+EXPECTED_VAL=1234	

.PHONY: run dve clean

# run simulation.
# run-time parameters (plusarg) can be passed in like this.
# +{name}={value}
run: simv
	./simv -l simv.log +actual_val=1234

# this creates an executable.
simv:
	vcs +v2k -sverilog -full64 -f sv.include -l vcs.log \
		-debug_pp -timescale=1ps/1ps +vcs+vcdpluson \
		+lint=all,noSVA-UA,noSVA-NSVU,noVCDE,noNS \
		$(VCS_INCDIR) \
		$(VCS_DEFINE)

# this opens the waveform viewer.
dve:
	dve -full64 -vpd vcdplus.vpd &

# clean all the temporary files.
clean:
	rm -rf DVEfiles
	rm -rf csrc
	rm -rf simv.daidir simv.vdb
	rm -f ucli.key vcdplus.vpd simv *.tar.gz
	rm -f simv.log vcs.log
