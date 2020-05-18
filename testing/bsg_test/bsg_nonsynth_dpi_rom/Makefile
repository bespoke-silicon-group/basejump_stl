.DEFAULT_GOAL := test_rom

BASEJUMP_STL_DIR := $(abspath ../../../)

#VERILATOR=/home/drichmond/Research/repositories/git/verilator/bin/verilator
#VERILATOR_ROOT=/home/drichmond/Research/repositories/git/verilator
VERILATOR_ROOT=/usr/share/verilator
VERILATOR=verilator
VSOURCES += $(BASEJUMP_STL_DIR)/testing/bsg_test/bsg_nonsynth_dpi_rom/top.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_rom.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.v
VINCLUDES += -I$(BASEJUMP_STL_DIR)/bsg_misc/

CFLAGS += -CFLAGS -std=c++11
CFLAGS +=-CFLAGS -I$(BASEJUMP_STL_DIR)/bsg_test/
CXXSOURCES += main.cpp

INCLUDES += -I$(VERILATOR_ROOT)/include
INCLUDES += -I$(VERILATOR_ROOT)/include/vltstd
INCLUDES += -I$(BASEJUMP_STL_DIR)/bsg_test/
INCLUDES += -Iobj_dir

obj_dir/Vtop.mk: $(VSOURCES) 
	$(VERILATOR) -cc $^ -Wno-lint $(VINCLUDES) $(CFLAGS) $(CXXSOURCES) -o test_rom

%__ALL.a: %.mk
	$(MAKE) -j -C $(dir $@) -f $(notdir $<) default

%.o: $(VERILATOR_ROOT)/include/%.cpp
	g++ -MMD -I$(VERILATOR_ROOT)/include -I$(VERILATOR_ROOT)/include/vltstd -DVL_PRINTF=printf -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TRACE=0 -std=c++11 -c -o $@ $^

%.o: $(BASEJUMP_STL_DIR)/bsg_test/%.cpp
	g++ -MMD -I$(VERILATOR_ROOT)/include $(INCLUDES) -DVL_PRINTF=printf -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TRACE=0 -std=c++11 -c -o $@ $<

main.o: main.cpp obj_dir/Vtop__ALL.a
	g++ -MMD -I$(VERILATOR_ROOT)/include $(INCLUDES) -DVL_PRINTF=printf -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TRACE=0 -std=c++11 -c -o $@ $<

test_rom: verilated.o verilated_dpi.o main.o obj_dir/Vtop__ALL.a bsg_nonsynth_dpi_clock_gen.o 
	g++ -std=c++11 $^ -o $@

clean:
	rm -rf obj_dir test_rom *.o *.d

.PRECIOUS: obj_dir/Vtop.mk
