export TESTING_COCOTB_COMMON_MK_DIR := $(realpath $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))))

include $(TESTING_COCOTB_COMMON_MK_DIR)/../cocotb_tools.mk

#===============================================================================
# bsg_cocotb.tail_rules.mk
#
# This makefile is to be included at the end of a cocotb test makefile. It
# defines the main generalized makefile targets that will be used throughout
# the testing infrastructure.
#

# Set the default goal to run all test parameterizations.
.DEFAULT_GOAL := test.all

# This is the makefile that is going to run the cocotb test. We copy this into
# the sweep test run directory and then call make on this makefile.
RUN_COCOTB_MAKEFILE := $(TESTING_COCOTB_COMMON_MK_DIR)/run_cocotb.mk

#===============================================================================
# Spawn Test Parameterization Targets
#
# Here we define a function to spawn a test and clean.test targets for a given
# parameterization. Then we go through and actually spwan the targets for each
# of the defined parameterizations.
#

# Collection of all test targets that get spawned
ALL_TEST_TARGETS :=

# Function to spawn a test.% and clean.test.% target for the given param value
define add_test=

TEST_NAME_$1 :=$$(word 1,$$(BSG_PARAM_SWEEP_PARAMS_$1))
TEST_PVAL_$1 :=$$(wordlist 2,$$(words $$(BSG_PARAM_SWEEP_PARAMS_$1)),$$(BSG_PARAM_SWEEP_PARAMS_$1))

ALL_TEST_TARGETS += test.$$(TEST_NAME_$1)

test.$$(TEST_NAME_$1): test.%: build_tools
	mkdir -p $$*
	cp $$(RUN_COCOTB_MAKEFILE) $$*/Makefile
	$$(eval export BSG_TOPLEVEL_PVALS=$$(TEST_PVAL_$1))
	$$(eval export BSG_ADDITIONAL_PYTHONPATH=$$(CURDIR))
	cd $$* && $(COCOTB_VENV_ACTIVATE) && make sim 2>&1 | tee -i run.log

clean.test.$$(TEST_NAME_$1): clean.test.%:
	rm -rf $$*

endef

# Spawn all of the test cases based on the BSG_PARAM_SWEEP_* variables.
$(foreach i, $(shell for i in {$(BSG_PARAM_SWEEP_START)..$(BSG_PARAM_SWEEP_STOP)}; do echo $$i; done), $(eval $(call add_test,$i)))

#===============================================================================
# Main Targets
#
# All other standard target declarations. Makefiles that include this makefile
# can extend the prereq list for these targets to do design specific actions
# before these targets are executed.
#

# Alias run target for all test cases. Can run in parallel using the -j flag.
test.all: $(ALL_TEST_TARGETS)

# Alias clean target for all test cases. Can run in parallel using the -j flag.
clean.test.all: $(addprefix clean.,$(ALL_TEST_TARGETS))

# Clean target (doesn't clean test runs)
clean:
	rm -f *.pyc

# Alias target to clean everything (prestine)
deep_clean: clean.test.all clean

