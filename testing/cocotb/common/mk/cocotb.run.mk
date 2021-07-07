#===============================================================================
# run_cocotb.mk
#
# This makefile is a standard cocotb makefile with a BSG twist. In our testing
# infrastructure, we define environment variables that need to be translated to
# the variables and structure that cocotb is expecting. This makefile get's
# copied into each testing parameterization's subfolder before being executed.
#
# The comments for what each of the cocotb variables does is taken directly
# from the cocotb documentation.
#

# Selects which simulator Makefile to use (most of the time this is set before)
SIM ?= verilator
#SIM ?= vcs

# Define the main RTL language
TOPLEVEL_LANG ?= verilog

# A list of the Verilog source files to include.
VERILOG_SOURCES ?= $(BSG_VERILOG_SOURCES)

# Used to indicate the instance in the hierarchy to use as the DUT. If this
# isn’t defined then the first root instance is used.
TOPLEVEL ?= $(BSG_TOPLEVEL_MODULE)

# The name of the module(s) to search for test functions. Multiple modules can
# be specified using a comma-separated list.
MODULE ?= $(BSG_PY_TEST_MODULES)

# Seed the Python random module to recreate a previous test stimulus.
export RANDOM_SEED ?= 0

# If defined, log lines displayed in terminal will be shorter. It will print
# only time, message type (INFO, WARNING, ERROR) and log message.
export COCOTB_REDUCED_LOG_FMT

# Parameters that is used by the bsg_top_params() function to create a dict for
# toplevel parameters.
export COCOTB_PARAM_LIST := $(BSG_TOPLEVEL_PVALS)

# Search path for python imports.
PYTHONPATH := $(PYTHONPATH):$(TESTING_COCOTB_DIR)/common/bsg_cocotb_lib:$(BSG_ADDITIONAL_PYTHONPATH)

#===============================================================================
# VCS Specific Setup
#
ifeq ($(SIM),vcs)

# Bin directory for vcs
VCS_BIN_DIR ?= $(VCS_HOME)/bin

# Any arguments or flags to pass to the compile stage of the simulation.
COMPILE_ARGS ?= \
    -timescale=1ps/1ps \
    $(addprefix +incdir+,$(BSG_VERILOG_INCDIRS)) \
    $(addprefix -pvalue+,$(BSG_TOPLEVEL_PVALS)) \
    $(BSG_COMPILE_ARGS)

# Any arguments or flags to pass to the execution of the compiled simulation.
#SIM_ARGS ?=

# Passed to both the compile and execute phases of simulators with two rules,
# or passed to the single compile and run command for simulators which don’t
# have a distinct compilation stage.
#EXTRA_ARGS ?=

# Use to add additional dependencies to the compilation target; useful for
# defining additional rules to run pre-compilation or if the compilation phase
# depends on files other than the RTL sources listed in VERILOG_SOURCES or
# VHDL_SOURCES.
#CUSTOM_COMPILE_DEPS ?=

#===============================================================================
# Verilator Specific Setup
#
else ifeq ($(SIM),verilator)

# Install directory for verilator
VERILATOR_ROOT ?= $(TESTING_COCOTB_DIR)/tools/verilator/install
PATH := $(VERILATOR_ROOT)/bin/:$(PATH)

# Set time-precision for toplevel testbench
COCOTB_HDL_TIMEPRECISION ?= 1ns

# Any arguments or flags to pass to the compile stage of the simulation.
COMPILE_ARGS ?= \
    $(addprefix +incdir+,$(BSG_VERILOG_INCDIRS)) \
    $(addprefix -pvalue+,$(BSG_TOPLEVEL_PVALS)) \
    $(BSG_COMPILE_ARGS)

# Any arguments or flags to pass to the execution of the compiled simulation.
#SIM_ARGS ?=

# Passed to both the compile and execute phases of simulators with two rules,
# or passed to the single compile and run command for simulators which don’t
# have a distinct compilation stage.
EXTRA_ARGS ?= --trace --trace-structs --coverage

# Use to add additional dependencies to the compilation target; useful for
# defining additional rules to run pre-compilation or if the compilation phase
# depends on files other than the RTL sources listed in VERILOG_SOURCES or
# VHDL_SOURCES.
#CUSTOM_COMPILE_DEPS ?=

endif

# Include standard cocotb makefile infrastructure
include $(shell cocotb-config --makefiles)/Makefile.sim

