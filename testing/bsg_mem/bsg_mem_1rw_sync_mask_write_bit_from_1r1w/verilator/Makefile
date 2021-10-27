# AM
# 24 Jul 2021

TOP = ../../../..

# Change REPLACE to test other variants
REPLACE = bsg_mem_1rw_sync_mask_write_bit_from_1r1w

# Change the paths appropriately
TOP_FILE = $(TOP)/bsg_mem/$(REPLACE).v
VERILATOR_INCLUDE = /usr/local/share/verilator/include/
BASEJUMP_INCLUDE = $(TOP)/bsg_misc/ $(TOP)/bsg_mem/
INCLUDES = $(foreach x,$(VERILATOR_INCLUDE),-I$(x)) \
	$(foreach x,$(BASEJUMP_INCLUDE),-I$(x)) \

# Default variables
RUNTIME = 100000
ELS_P = 60
WIDTH_P = 20
# Values to iterate over
ELS   = 33 64
WIDTH = 16 7

# Stream edition to change instance names in CPP testbench
generate = cp test_bsg_template test_bsg.cpp &&	sed -i 's/REPLACE/$(REPLACE)/' test_bsg.cpp

verilate = verilator -cc -Wall -Wno-DECLFILENAME -Wno-UNUSED \
  $(TOP_FILE) $(INCLUDES) \
	-Gwidth_p=$(WIDTH_P) -Gels_p=$(ELS_P) -Gverbose_p=1

compile = g++ test_bsg.cpp obj_dir/*.cpp $(VERILATOR_INCLUDE)/verilated.cpp \
  -I$(VERILATOR_INCLUDE) -I./obj_dir/ -o v_out \
	-DWIDTH_P=$(WIDTH_P) -DELS_P=$(ELS_P) -DRUNTIME=$(RUNTIME)

# Single iteration
.DEFAULT_GOAL := iter
iter:
	$(generate)
	$(verilate)
	$(compile)
	./v_out >> transcript
	$(stats)

# For multiple iterations based off of default variables previously set
.SILENT:
loopy:
	$(foreach x,$(commandsD),run.$(x))
	for i in $(ELS);                            \
	do                                          \
		for j in $(WIDTH);                        \
		do                                        \
			$(MAKE) $(iter) WIDTH_P=$$j ELS_P=$$i;  \
		done                                      \
	done

# Run after iter or loopy for statistics
stats:
	echo Total errors
	grep "ERROR" transcript | wc -l
	echo Total writes issued
	grep "v | w" transcript | wc -l
	echo Total writes performed
	grep "w_en 1" transcript | wc -l
	echo Total reads issued
	grep "v | r" transcript | wc -l
	echo Total reads performed
	grep "r_en 1" transcript | wc -l

clean:
	rm -rf obj_dir/ v_out transcript test_bsg.cpp
