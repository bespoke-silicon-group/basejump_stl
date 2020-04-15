.DEFAULT_GOAL := test_fifo_dpi

BASEJUMP_STL_DIR := $(abspath ../../../)

#VERILATOR=/home/drichmond/Research/repositories/git/verilator/bin/verilator
#VERILATOR_ROOT=/home/drichmond/Research/repositories/git/verilator
VERILATOR_ROOT=/usr/share/verilator
VERILATOR=verilator
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

CFLAGS += -CFLAGS -std=c++11
CFLAGS +=-CFLAGS -I$(BASEJUMP_STL_DIR)/bsg_test/
obj_dir/V%.mk: %.v $(VSOURCES) bsg_nonsynth_clock_gen_dpi.v 
	$(VERILATOR) --exe -cc $^ -Wno-lint  $(VINCLUDES) $(CFLAGS) main.cpp

%__ALL.a: %.mk
	$(MAKE) -j -C $(dir $@) -f $(notdir $<) default

CXXSOURCES += main.cpp
CXXSOURCES += $(VERILATOR_ROOT)/include/verilated.cpp
CXXSOURCES += $(VERILATOR_ROOT)/include/verilated_dpi.cpp
CXXDEFINES += 

INCLUDES += -I$(VERILATOR_ROOT)/include
INCLUDES += -I$(VERILATOR_ROOT)/include/vltstd
INCLUDES += -I$(BASEJUMP_STL_DIR)/bsg_test/
INCLUDES += -Iobj_dir


test_fifo_dpi: $(CXXSOURCES) obj_dir/Vtop__ALL.a 
	g++ -std=c++11 $(INCLUDES) $^ -o $@

clean:
	rm -rf obj_dir test_fifo_dpi

.PRECIOUS: obj_dir/Vtop.mk
