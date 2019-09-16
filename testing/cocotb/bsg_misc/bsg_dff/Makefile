BASEJUMP_STL_DIR :=$(shell git rev-parse --show-toplevel)

#===============================================================================
# VCS Setup
#
# Synopsys VCS setup. If you have access to bsg_cadenv and are running on a
# compatible machine, then you can simply put the bsg_cadenv directory one
# level up from this repository. Otherwise, you can simply set the VCS_HOME and
# LM_LICENSE_FILE varibales manually.
#

-include $(BASEJUMP_STL_DIR)/../bsg_cadenv/cadenv.mk

export LM_LICENSE_FILE ?=
export VCS_HOME ?=

#===============================================================================
# Design Setup
#
# Basic design setup. The BSG_TOPLEVEL_MODULE is the name of the RTL module
# that is being tested. The BSG_PY_TEST_MODULES is a comma separated list of
# python modules that will be driving the test (most of the time, this will be
# the name of the python file without the extension). The BSG_VERILOG_SOURCES
# list contains all of the RTL files required to build the design. Finally, the
# BSG_VERILOG_INCDIR list contains all of the directories to add to the include
# search path.
#

export BSG_TOPLEVEL_MODULE := bsg_dff

export BSG_PY_TEST_MODULES := test_bsg

export BSG_VERILOG_SOURCES := $(BASEJUMP_STL_DIR)/bsg_misc/bsg_dff.v

export BSG_VERILOG_INCDIRS :=

#===============================================================================
# Parameter Sweeping Setup
#
# For each parameterization, you will create a variable called
# BSG_PARAM_SWEEP_PARAMS_# where # is the number associated with the
# parameterization. Note: Best practice for the parameterization numbers is to
# have all numbers continuously increasing starting with 1.
# 
# Each BSG_PARAM_SWEEP_PARAMS_# variable is a space separated list with the
# following format:
# 
# BSG_PARAM_SWEEP_PARAMS_# = <name> [[parameter_name=value] ...]
# 
# The first item (which must exist!) is the <name> of the parameterization.
# Mentioned before, this allows you to run tests on just this parameterization if
# you want. This will also be the name of the directory where tests for this
# parameterization are run. All subsequent items make up the actuall
# parameterization. For each toplevel parameter you want to set, add an item in
# the format parameter_name=value. You may specify zero or more parameters this
# way.
# 
# Finally, set the BSG_PARAM_SWEEP_COUNT_START and BSG_PARAM_SWEEP_COUNT_STOP
# variables equal to the first and last parameterization you want to instantiate
# (inclusive). This should correspond with the # value in the
# BSG_PARAM_SWEEP_PARAMS_# variables.
#

BSG_PARAM_SWEEP_PARAMS_1 := run_w8  width_p=8
BSG_PARAM_SWEEP_PARAMS_2 := run_w32 width_p=32
BSG_PARAM_SWEEP_PARAMS_3 := run_w27 width_p=27

BSG_PARAM_SWEEP_START := 1
BSG_PARAM_SWEEP_STOP  := 3

#===============================================================================
# Finish the Makefile
#
# Include the common bsg cocotb makefile. This will complete the makefile by
# defining all the makefile targets based on the setup above.
#

include $(BASEJUMP_STL_DIR)/testing/cocotb/common/mk/bsg_cocotb.tail_rules.mk

