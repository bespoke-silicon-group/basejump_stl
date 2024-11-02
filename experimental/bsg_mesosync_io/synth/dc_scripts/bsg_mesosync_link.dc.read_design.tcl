proc bsg_check_not_null {check_me error_string} {
  if {$check_me==""} {
    echo "### BSG ### $error_string"
    exit
  }
  return $check_me
}


file mkdir ./core_lib
define_design_lib core_LIB -path ./core_lib
set SRC_PATH ../src

set CFG_TAG_PATH    ../../config_net/src
set DEFINES_PATH    ../../bsg_misc
set ASYNC_PATH      ../../bsg_async
set DATA_FLOW_PATH  ../../bsg_dataflow
set MISC_PATH       ../../bsg_misc
set MEM_PATH        ../../bsg_mem
set GTECH_DIR       /gro/cad/synopsys/icc/J-2014.09-SP4/packages/gtech/src_ver

set rtl_files [list $DEFINES_PATH/bsg_defines.sv \
                    $DEFINES_PATH/bsg_circular_ptr.sv \
                    $SRC_PATH/config_defs.sv \
                    $GTECH_DIR/GTECH_NAND2.v \
                    $CFG_TAG_PATH/rNandMeta.v \
                    $CFG_TAG_PATH/relay_node.v \
                    $CFG_TAG_PATH/config_node.v \
                    $DATA_FLOW_PATH/bsg_fifo_1r1w_small.sv \
                    $MISC_PATH/bsg_counter_up_down.sv \
                    $MISC_PATH/bsg_counter_up_down_variable.sv \
                    $MISC_PATH/bsg_counter_dynamic_limit.sv \
                    $MEM_PATH/bsg_mem_1r1w.sv \
                    $DATA_FLOW_PATH/bsg_channel_narrow.sv \
                    $DATA_FLOW_PATH/bsg_fifo_1r1w_small_credit_on_input.sv \
                    $DATA_FLOW_PATH/bsg_ready_to_credit_flow_converter.sv \
                    $DATA_FLOW_PATH/bsg_two_fifo.sv \
                    $DATA_FLOW_PATH/bsg_relay_fifo.sv \
                    $DATA_FLOW_PATH/bsg_credit_to_token.sv \
                    $DATA_FLOW_PATH/bsg_fifo_1r1w_narrowed.sv \
                    $ASYNC_PATH/bsg_launch_sync_sync.sv \
                    $SRC_PATH/bsg_mesosync_core.sv \
                    $SRC_PATH/bsg_ddr_sampler.sv \
                    $SRC_PATH/bsg_logic_analyzer.sv \
                    $SRC_PATH/bsg_mesosync_link.sv \
                    $SRC_PATH/bsg_mesosync_input.sv \
                    $SRC_PATH/bsg_mesosync_output.sv]
	
analyze -format sverilog $rtl_files

elaborate bsg_mesosync_link

current_design bsg_mesosync_link
