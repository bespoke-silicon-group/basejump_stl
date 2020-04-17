.DEFAULT_GOAL := test_fifo_dpi

BASEJUMP_STL_DIR := $(abspath ../../../)

VERILATOR=/home/drichmond/Research/repositories/git/verilator/bin/verilator
VERILATOR_ROOT=/home/drichmond/Research/repositories/git/verilator
#VERILATOR_ROOT=/usr/share/verilator
#VERILATOR=verilator
VSOURCES += $(BASEJUMP_STL_DIR)/testing/bsg_test/bsg_nonsynth_dpi/top.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_defines.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_reset_gen.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_fifo_to_dpi.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_to_fifo.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_clock_gen_dpi.v 
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_fifo_1r1w_small_unhardened.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_fifo_tracker.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_circular_ptr.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_1r1w.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_1r1w_synth.v
VINCLUDES += -I$(BASEJUMP_STL_DIR)/bsg_misc/

CFLAGS += -CFLAGS -std=gnu++11
CFLAGS +=-CFLAGS -I$(BASEJUMP_STL_DIR)/bsg_test/
#CXXSOURCES += $(VERILATOR_ROOT)/include/verilated.cpp
#CXXSOURCES += $(VERILATOR_ROOT)/include/verilated_dpi.cpp
CXXSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_clock_gen_dpi.cpp
CXXSOURCES += main.cpp

INCLUDES += -I$(VERILATOR_ROOT)/include
INCLUDES += -I$(VERILATOR_ROOT)/include/vltstd
INCLUDES += -I$(BASEJUMP_STL_DIR)/bsg_test/
INCLUDES += -Iobj_dir

obj_dir/Vtop.mk: $(VSOURCES) 
	$(VERILATOR) -O3 --exe -cc $^ -Wno-lint $(VINCLUDES) $(CFLAGS) $(CXXSOURCES) --threads 4

obj_dir/Vtop: obj_dir/Vtop.mk
	$(MAKE) -j -C $(dir $@) -f $(notdir $<) Vtop

%__ALL.a: %.mk
	$(MAKE) -j -C $(dir $@) -f $(notdir $<) default

%.o: $(VERILATOR_ROOT)/include/%.cpp
	g++ -MMD -I$(VERILATOR_ROOT)/include -I$(VERILATOR_ROOT)/include/vltstd -DVL_PRINTF=printf -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TRACE=0 -DVL_THREADED -std=gnu++11 -c -o $@ $^

%.o: $(BASEJUMP_STL_DIR)/bsg_test/%.cpp
	g++ -MMD -I$(VERILATOR_ROOT)/include $(INCLUDES) -DVL_PRINTF=printf -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TRACE=0 -std=gnu++11 -DVL_THREADED -c -o $@ $<

main.o: main.cpp obj_dir/Vtop__ALL.a
	g++ -MMD -I$(VERILATOR_ROOT)/include $(INCLUDES) -DVL_PRINTF=printf -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TRACE=0 -std=gnu++11 -DVL_THREADED -c -o $@ $<

test_fifo_dpi: verilated.o verilated_threads.o verilated_dpi.o main.o obj_dir/Vtop__ALL.a bsg_nonsynth_clock_gen_dpi.o 
	g++ -std=gnu++11 $^ -o $@ -pthread -lpthread

clean:
	rm -rf obj_dir test_fifo_dpi *.o *.d

.PRECIOUS: obj_dir/Vtop.mk
