CAD_PATH        = ../../../cad/
SRC_PATH        = ../src
TESTBENCH_PATH  = ../tests/normal_input_test
TESTBENCH			  = $(TESTBENCH_PATH)/mesosynctb.v

include $(CAD_PATH)/common/mk/cadenv.mk

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

HDL_SOURCE += $(CAD_PATH)/flow/vcs/setup/vcsdumper.v $(TESTBENCH) 

include $(CAD_PATH)/flow/vcs/setup/vcs.mk
