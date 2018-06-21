CAD_PATH        = ../../../cad/
SRC_PATH        = ../src
CFG_TAG_PATH    = ../../config_net/src
DEFINES_PATH    = ../../bsg_misc
ASYNC_PATH      = ../../bsg_async
DATA_FLOW_PATH  = ../../bsg_dataflow
MISC_PATH       = ../../bsg_misc
MEM_PATH        = ../../bsg_mem
TESTBENCH_PATH  = ../tests
TESTBENCH			  = $(TESTBENCH_PATH)/mesosynctb_gate_level.v \
									$(CFG_TAG_PATH)/../sim/send_config_tag.v

include $(CAD_PATH)/common/mk/cadenv.mk

TSMC_LIB =  /gro/cad/mosis/pdk/tsmc/cl025g/std_cells/Rev_2004q2v1/aci/sc/verilog/tsmc25.v
DW_LIB = /gro/cad/synopsys/pkg/pkg_2004-2007/dw/Z-2007.03/dw/sim_ver
GTECH_DIR = /gro/cad/synopsys/icc/J-2014.09-SP4/packages/gtech/src_ver

VCS_OPTIONS += +incdir+$(CURDIR)/$(SRC_PATH)
VCS_OPTIONS += +incdir+$(CURDIR)/$(CFG_TAG_PATH)
VCS_OPTIONS += +incdir+$(CURDIR)/$(TESTBENCH_PATH)
VCS_OPTIONS += +incdir+$(CURDIR)/$(DEFINES_PATH) 
VCS_OPTIONS += +incdir+$(GTECH_DIR)
VCS_OPTIONS += +incdir+$(GTECH_SIM_LIB)
VCS_OPTIONS += +notimingcheck


BUILD_GATE_LEVEL ?= 1
VPD								= 1

ifeq ($(BUILD_GATE_LEVEL),1)
  HDL_SOURCE  = $(DEFINES_PATH)/bsg_defines.v 
  HDL_SOURCE +=	$(SRC_PATH)/config_defs.v 
  HDL_SOURCE += $(TSMC_LIB)
  HDL_SOURCE +=	$(MISC_PATH)/bsg_counter_up_down.v 
  HDL_SOURCE +=	$(DATA_FLOW_PATH)/bsg_flow_counter.v 
  HDL_SOURCE += ./../synth/results/bsg_mesosync_link.mapped.v
else
  HDL_SOURCE  = $(DEFINES_PATH)/bsg_defines.v 
  HDL_SOURCE +=	$(DEFINES_PATH)/bsg_circular_ptr.v
  HDL_SOURCE += $(GTECH_DIR)/GTECH_NAND2.v
  HDL_SOURCE +=	$(SRC_PATH)/config_defs.v 
  HDL_SOURCE +=	$(CFG_TAG_PATH)/relay_node.v 
  HDL_SOURCE +=	$(CFG_TAG_PATH)/config_node.v 
  HDL_SOURCE +=	$(CFG_TAG_PATH)/rNandMeta.v 
  HDL_SOURCE +=	$(DATA_FLOW_PATH)/bsg_fifo_1r1w_small.v 
  HDL_SOURCE +=	$(MISC_PATH)/bsg_counter_up_down.v 
  HDL_SOURCE +=	$(MISC_PATH)/bsg_counter_up_down_variable.v 
  HDL_SOURCE +=	$(MISC_PATH)/bsg_counter_dynamic_limit.v 
  HDL_SOURCE +=	$(MEM_PATH)/bsg_mem_1r1w.v
  HDL_SOURCE +=	$(DATA_FLOW_PATH)/bsg_channel_narrow.v 
  HDL_SOURCE +=	$(DATA_FLOW_PATH)/bsg_fifo_1r1w_small_credit_on_input.v 
  HDL_SOURCE +=	$(DATA_FLOW_PATH)/bsg_ready_to_credit_flow_converter.v 
  HDL_SOURCE +=	$(DATA_FLOW_PATH)/bsg_two_fifo.v 
  HDL_SOURCE +=	$(DATA_FLOW_PATH)/bsg_relay_fifo.v 
  HDL_SOURCE +=	$(DATA_FLOW_PATH)/bsg_flow_counter.v 
  HDL_SOURCE +=	$(DATA_FLOW_PATH)/bsg_credit_to_token.v 
  HDL_SOURCE +=	$(DATA_FLOW_PATH)/bsg_fifo_1r1w_narrowed.v 
  HDL_SOURCE += $(ASYNC_PATH)/bsg_launch_sync_sync.v
  HDL_SOURCE +=	$(SRC_PATH)/bsg_mesosync_core.v 
  HDL_SOURCE +=	$(SRC_PATH)/bsg_ddr_sampler.v 
  HDL_SOURCE +=	$(SRC_PATH)/bsg_logic_analyzer.v 
  HDL_SOURCE +=	$(SRC_PATH)/bsg_mesosync_link.v
  HDL_SOURCE += $(SRC_PATH)/bsg_mesosync_input.v 
  HDL_SOURCE += $(SRC_PATH)/bsg_mesosync_output.v 
	
endif

HDL_SOURCE += $(CAD_PATH)/flow/vcs/setup/vcsdumper.v $(TESTBENCH) 

include $(CAD_PATH)/flow/vcs/setup/vcs.mk
