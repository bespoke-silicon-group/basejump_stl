.DEFAULT_GOAL := test_fifo_dpi

BASEJUMP_STL_DIR := $(abspath ../../../)
VERILATOR_ROOT=/usr/share/verilator

VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_defines.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_reset_gen.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_fifo_to_dpi.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_to_fifo.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_fifo_1r1w_small_unhardened.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_fifo_tracker.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_circular_ptr.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_1r1w.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_1r1w_synth.v
VINCLUDES += -I$(BASEJUMP_STL_DIR)/bsg_misc/

obj_dir/V%.mk: %.v $(VSOURCES) bsg_nonsynth_clock_gen_dpi.v 
	verilator -cc $^ -Wno-lint  $(VINCLUDES)

%__ALL.a: %.mk
	$(MAKE) -j -C $(dir $@) -f $(notdir $<) default

CXXSOURCES += main.cpp
CXXSOURCES += $(VERILATOR_ROOT)/include/verilated.cpp
CXXSOURCES += $(VERILATOR_ROOT)/include/verilated_dpi.cpp

INCLUDES += -Iobj_dir
INCLUDES += -I$(VERILATOR_ROOT)/include
INCLUDES += -I$(VERILATOR_ROOT)/include/vltstd

test_fifo_dpi: $(CXXSOURCES) obj_dir/Vtop__ALL.a 
	g++ -std=c++11 $(INCLUDES) $^ -o $@

clean:
	rm -rf obj_dir test_fifo_dpi
