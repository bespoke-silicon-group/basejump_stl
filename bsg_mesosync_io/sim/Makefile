CAD_PATH        = ../../../cad/
SRC_PATH        = ../src
CFG_TAG_PATH    = ../../config_net/src
DEFINES_PATH    = ../../bsg_misc
#TESTBENCH_PATH  = ../tests/fifo_feed_test
TESTBENCH_PATH  = ../tests/LA_test
TESTBENCH			  = $(TESTBENCH_PATH)/mesosynctb.v

include $(CAD_PATH)/common/mk/cadenv.mk

DW_LIB = /gro/cad/synopsys/pkg/pkg_2004-2007/dw/Z-2007.03/dw/sim_ver
VCS_OPTIONS += +incdir+$(CURDIR)/$(SRC_PATH)
VCS_OPTIONS += +incdir+$(CURDIR)/$(CFG_TAG_PATH)
VCS_OPTIONS += +incdir+$(CURDIR)/$(TESTBENCH_PATH)

BUILD_GATE_LEVEL ?= 0
VPD								= 0

ifeq ($(BUILD_GATE_LEVEL),1)
	HDL_SOURCE = ./../synth/results/core_flattened.mapped.v
else
  HDL_SOURCE  = $(DEFINES_PATH)/bsg_defines.v \
								$(CFG_TAG_PATH)/config_node.v \
								$(CFG_TAG_PATH)/config_snooper.v \
								$(CFG_TAG_PATH)/relay_node.v \
								$(SRC_PATH)/two_in_one_out_fifo.v \
	  					  $(SRC_PATH)/bsg_logic_analyzer.v \
							  $(SRC_PATH)/bsg_mux_bitwise.v \
							  $(SRC_PATH)/bsg_mesosync_io.v
endif

HDL_SOURCE += $(CAD_PATH)/flow/vcs/setup/vcsdumper.v $(TESTBENCH) 

include $(CAD_PATH)/flow/vcs/setup/vcs.mk
