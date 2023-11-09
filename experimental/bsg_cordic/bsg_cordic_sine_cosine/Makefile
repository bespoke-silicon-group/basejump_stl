#Default goal for make is compilation to the executable 'Vbsg_cordic_sine_cosine'.
#Use 'make run' to to run the executable and compute the error analysis.
#TRACE variable is used to enable tracing. While doing 'make run' give 
#variable value of TRACE=1 at command line;Use 'make run TRACE=1.
#Please be very careful of the stray empty spaces ' ' while giving arguments to
#make. Make is very sensitive to empty spaces in the command line as well as 
#while declaring variables.

.PHONY: clean

FILE_DEL = $(VERI_DIR) CORDIC_sine_cosine.vcd $(GENERATED_VERILOG_FILE) params_def.h

#Use 'make clean' to remove the trace and verilated files. Define FILE_DEL variable
#with files folder to verilated files if not using default 'obj_dir' directory name. 
#To have a different folder name for Verilated files, give the folder name to make 
#with variable VERI_DIR;Use 'make run VERI_DIR=your_desired_name'

GENERATED_VERILOG_FILE = bsg_cordic_sine_cosine.v

#To generate the default design with the parameters at line #58, please use 
# 'make bsg_cordic_sine_cosine.v'. 

SRC_FILES = $(GENERATED_VERILOG_FILE) bsg_cordic_sine_cosine_stage.sv 

TEST_FILES = bsg_cordic_sine_cosine_test.cpp 

VERI_DIR = obj_dir

#^^To have a different folder name for Verilated files,
#give the folder name to make with variable VERI_DIR;Use 'make run VERI_DIR=your_desired_name'

TRACE = 0

VFLAGS = -Wall --cc --exe --Mdir 

VLINT_OFF = -Wno-UNUSED

.DEFAULT_GOAL := $(VERI_DIR)/Vbsg_cordic_sine_cosine

#If installed verilator isn't included in your environment's default path,
#use VERILATOR_PATH to point to the installed 'verilator' executable.
#Use 'make run VERILATOR_PATH=where/verilator/is/installed/verilator-'version'/bin/verilator'

VERILATOR_PATH := verilator

run: $(VERI_DIR)/Vbsg_cordic_sine_cosine
	$(VERI_DIR)/Vbsg_cordic_sine_cosine

Vbsg_cordic_sine_cosine.mk: $(SRC_FILES) $(TEST_FILES)
ifeq ($(TRACE),1)
		$(VERILATOR_PATH)  $(VFLAGS) $(VERI_DIR) --trace $(SRC_FILES) $(TEST_FILES) $(VLINT_OFF)
else
		$(VERILATOR_PATH) $(VFLAGS) $(VERI_DIR) $(SRC_FILES) $(TEST_FILES) $(VLINT_OFF)	
endif

$(VERI_DIR)/Vbsg_cordic_sine_cosine: Vbsg_cordic_sine_cosine.mk
		make -j -C $(VERI_DIR) -f Vbsg_cordic_sine_cosine.mk Vbsg_cordic_sine_cosine
$(GENERATED_VERILOG_FILE):
		echo -n > $(GENERATED_VERILOG_FILE)
		python3 bsg_sine_cosine_script.py 21 32 14 12 6 > $(GENERATED_VERILOG_FILE)
#										  ^^^^^^^^^^^^^
#Change the above parameters to generate the verilog design with desired parameters

clean:
		rm -rf $(FILE_DEL)