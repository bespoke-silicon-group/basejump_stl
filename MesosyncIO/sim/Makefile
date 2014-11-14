COMMON_PATH       = ../../../common/
SRC_PATH          = ../src
TESTBENCH_PATH    = ../tests/first
TESTBENCH			    = $(TESTBENCH_PATH)/mesosynctb.v

include $(COMMON_PATH)/cadenv.mk

DW_LIB = /gro/cad/synopsys/pkg/pkg_2004-2007/dw/Z-2007.03/dw/sim_ver
VCS_OPTIONS += +incdir+$(CURDIR)/$(SRC_PATH)
VCS_OPTIONS += +incdir+$(CURDIR)/$(TESTBENCH_PATH)

BUILD_GATE_LEVEL ?= 0
VPD								= 0

ifeq ($(BUILD_GATE_LEVEL),1)
	HDL_SOURCE = ./../synth/results/core_flattened.mapped.v
else
  HDL_SOURCE  = $(SRC_PATH)/two_in_one_out_fifo.v \
	  						$(SRC_PATH)/mesosyncIO.v 
endif

HDL_SOURCE += $(TESTBENCH) $(COMMON_PATH)/vcsdumper.v

include $(COMMON_PATH)/vcs.mk
