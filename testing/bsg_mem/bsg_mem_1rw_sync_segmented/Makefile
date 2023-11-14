# Edited to test bsg_mem_1rw_sync_mask_write_bit_segmented.sv

TOP = ../../..

########################### SIMULATION PARAMETERS ##########################
# place the parameters you want to scan here.
BSG_TESTME_FILES    =   bsg_mem_1rw_sync_segmented.sv
BSG_TESTME_DIR      =   
BSG_MISC_FILES      =   
BSG_ASYNC_FILES     = 
BSG_COMM_LINK_FILES =
BSG_DATAFLOW_FILES  = 
BSG_FSB_FILES       =
BSG_GUTS_FILES      =

BSG_TEST_FILES      = 
                       
TEST_MAIN   = test_bsg.sv
TEST_MODULE = test_bsg

ALL_FILES = $(foreach x,$(BSG_MISC_FILES),$(TOP)/bsg_misc/$(x)) \
              $(foreach x,$(BSG_ASYNC_FILES),$(TOP)/bsg_async/$(x)) \
              $(foreach x,$(BSG_FSB_FILES),$(TOP)/bsg_legacy/bsg_fsb/$(x)) \
              $(foreach x,$(BSG_GUTS_FILES),$(TOP)/bsg_guts/$(x)) \
              $(foreach x,$(BSG_COMM_LINK_FILES),$(TOP)/bsg_comm_link/$(x)) \
              $(foreach x,$(BSG_DATAFLOW_FILES),$(TOP)/bsg_dataflow/$(x)) \
              $(foreach x,$(BSG_TEST_FILES),$(TOP)/bsg_test/$(x)) \
              $(foreach x,$(BSG_TESTME_FILES),$(BSG_TESTME_DIR)/$(x)) \
              $(TEST_MAIN)

verilator_sim: verilator_build
	./obj_dir/Vtest_bsg

verilator_build: clean
	verilator --Wall --trace --cc --assert --prof-cfuncs -CFLAGS -std=c++11 --build \
    -I${TOP}/bsg_misc -I${TOP}/bsg_mem -I${TOP}/bsg_test \
    ${ALL_FILES} --top-module test_bsg \
	  -Wno-WIDTH -Wno-UNUSED -exe test_bsg.cpp

clean:
	rm -rf obj_dir waveform
