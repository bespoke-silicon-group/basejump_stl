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

# Define the main RTL language
TOPLEVEL_LANG ?= verilog

# Selects which simulator Makefile to use. 
SIM ?= vcs

# Bin directory for vcs (if not in PATH)
VCS_BIN_DIR ?= $(VCS_HOME)/bin

# A list of the Verilog source files to include.
VERILOG_SOURCES ?= $(BSG_VERILOG_SOURCES)

# Used to indicate the instance in the hierarchy to use as the DUT. If this
# isn’t defined then the first root instance is used.
TOPLEVEL ?= $(BSG_TOPLEVEL_MODULE)

# The name of the module(s) to search for test functions. Multiple modules can
# be specified using a comma-separated list.
MODULE ?= $(BSG_PY_TEST_MODULES)

# Any arguments or flags to pass to the compile stage of the simulation.
COMPILE_ARGS ?= -timescale=1ps/1ps \
                $(addprefix +incdir+,$(BSG_VERILOG_INCDIRS)) \
                $(addprefix -pvalue ,$(BSG_TOPLEVEL_PVALS))

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

# Seed the Python random module to recreate a previous test stimulus.
export RANDOM_SEED ?= 0

# If defined, log lines displayed in terminal will be shorter. It will print
# only time, message type (INFO, WARNING, ERROR) and log message.
export COCOTB_REDUCED_LOG_FMT

# Search path for python imports.
PYTHONPATH := $(PYTHONPATH):$(TESTING_COCOTB_COMMON_DIR)/bsg_cocotb_lib:$(BSG_ADDITIONAL_PYTHONPATH)

# Include standard cocotb makefile infrastructure
include $(shell cocotb-config --makefiles)/Makefile.inc
include $(shell cocotb-config --makefiles)/Makefile.sim

