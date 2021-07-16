
export BASEJUMP_STL_DIR = $(shell git rev-parse --show-toplevel)
include $(abspath $(BASEJUMP_STL_DIR)/../bsg_cadenv/cadenv.mk)
 
HIGHLIGHT = grep --color -E '^|Error|Warning|Implicit wire is used|Too few instance port connections|Port connection width mismatch|Width mismatch'

INCDIR = +incdir+$(BASEJUMP_STL_DIR)/bsg_misc
INCDIR += +incdir+$(BASEJUMP_STL_DIR)/bsg_test
INCDIR += +incdir+$(BASEJUMP_STL_DIR)/bsg_mem

VCS_OPTS = +v2k
VCS_OPTS += -R
VCS_OPTS += +lint=all,noSVA-UA,noSVA-NSVU,noVCDE,noNS
VCS_OPTS += -sverilog
VCS_OPTS += -full64
VCS_OPTS += -assert svaext
VCS_OPTS += -timescale=1ps/1ps
VCS_OPTS += +vcs+vcdpluson
VCS_OPTS += -l vcs.log
VCS_OPTS += -top testbench
VCS_OPTS += -f sv.include

# Scan parameter checking adapted from testing/bsg_mem/bsg_mem_1r1w/Makefile

# this is a list of all variables you want to vary for the simulation
scan_params = WIDTH_P ELS_P

# this is a list of all values for each variable in the scan_params list
# note; if you leave out values for a variable, then the product of the
# sets is null, and nothing will run.
WIDTH_P = 4 16 32 64 
ELS_P   = 4  5 16

# function that generates a string for each combination of the parameters;
# spaces separated by "@" signs.
bsg_param_scan = $(if $(1),$(foreach v__,$($(firstword $(1))),\
                    $(call bsg_param_scan,$(filter-out $(firstword $(1)),\
                    $(1)),$(2),$(3),$(4)@$(2)$(firstword $(1))$(3)$(v__))),\
                    $(4))

# this takes the parameters and creates a set of make targets, one for every 
# combination of the parameters
commands = $(call bsg_param_scan,$(scan_params),+define+,=)

# default rule: run all of the targets.
all: $(foreach x,$(commands),run.$(x))

# this runs an individual target
# we replace the @ with a space so that the parameters are used as 
# command line options
run.%:
	$(VCS) $(VCS_OPTS) $(INCDIR) +define+WIDTH_P=$(firstword $(subst @, ,$*)) +define+ELS_P=$(word 2,$(subst @, ,$*)) | $(HIGHLIGHT)

dve:
	$(DVE) -full64 -vpd vcdplus.vpd

clean:
	rm -rf DVEfiles
	rm -rf csrc
	rm -rf simv.daidir simv.vdb
	rm -f ucli.key vcdplus.vpd simv cm.log *.tar.gz vcs.log vc_hdrs.h
	rm -rf stack.info.*
