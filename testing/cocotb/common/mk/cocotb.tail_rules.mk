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
RUN_COCOTB_MAKEFILE := $(TESTING_COCOTB_DIR)/common/mk/cocotb.run.mk

# Python script to read the config json file for the test
READ_JSON_CONFIG_PY := $(TESTING_COCOTB_DIR)/common/py/read_json_config.py

# Read in the json configuration file
export BSG_TOPLEVEL_MODULE :=$(shell python $(READ_JSON_CONFIG_PY) $(CFG) toplevel)
export BSG_PY_TEST_MODULES :=$(shell python $(READ_JSON_CONFIG_PY) $(CFG) test_modules)
export BSG_VERILOG_SOURCES :=$(addprefix $(shell git rev-parse --show-toplevel)/,$(shell python $(READ_JSON_CONFIG_PY) $(CFG) filelist))
export BSG_VERILOG_INCDIRS :=$(addprefix $(shell git rev-parse --show-toplevel)/,$(shell python $(READ_JSON_CONFIG_PY) $(CFG) include))
export BSG_COMPILE_ARGS :=$(shell python $(READ_JSON_CONFIG_PY) $(CFG) compile_args)

#===============================================================================
# Spawn Test Parameterization Targets
#
# Here we define a function to spawn a test and clean.test targets for a given
# parameterization. Then we go through and actually spwan the targets for each
# of the defined parameterizations.
#

# Read from the json configuration file. This is a list of strings with each
# string being a configuration. The string has % characters that act as
# delimiters. The first delimited item is the name of the sweep and the rest of
# the items are parameters in the format name=value.
BSG_PARAMETER_SWEEP :=$(shell $(READ_JSON_CONFIG_PY) $(CFG) psweep)

# Collection of all test targets that get spawned
ALL_TEST_TARGETS :=

# Function to spawn a test.% and clean.test.% target for the given param value
define add_test=

# Add this test to the collection of all tests
ALL_TEST_TARGETS += test.$(word 1,$(subst %, ,$1))

# Run test target
test.$(word 1,$(subst %, ,$1)): test.%: build_tools
	mkdir -p run_$$*
	cp $$(RUN_COCOTB_MAKEFILE) run_$$*/Makefile
	$$(eval export BSG_TOPLEVEL_PVALS=$(wordlist 2,$(words $(subst %, ,$1)), $(subst %, ,$1)))
	$$(eval export BSG_ADDITIONAL_PYTHONPATH=$$(CURDIR))
	cd run_$$* && $(COCOTB_VENV_ACTIVATE) && make sim 2>&1 | tee -i run.log

# Clean test target
clean.test.$(word 1,$(subst %, ,$1)): clean.test.%:
	rm -rf run_$$*

endef

# Spawn all of the test cases based on the BSG_PARAM_SWEEP_* variables.
$(foreach i, $(BSG_PARAMETER_SWEEP), $(eval $(call add_test,$i)))

#===============================================================================
# Additional Targets
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
clean_all: clean.test.all clean

