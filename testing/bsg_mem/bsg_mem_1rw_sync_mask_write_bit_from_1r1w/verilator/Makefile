# AM
# 24 Jul 2021

TOP = ../../../../
VERILATOR_INCLUDE = /usr/local/share/verilator/include/

ELS_P = 20
WIDTH_P = 8
CYCLES_P = 1000000

verilate = verilator -cc -Wall -Wno-DECLFILENAME $(TOP)/hard/ultrascale_plus/bsg_mem/bsg_mem_1rw_sync_mask_write_bit_from_1r1w.v -I$(TOP)/bsg_misc/ -Gwidth_p=$(WIDTH_P) -Gels_p=$(ELS_P)

compile = g++ test_bsg.cpp obj_dir/*.cpp $(VERILATOR_INCLUDE)/verilated.cpp -I$(VERILATOR_INCLUDE) -I./obj_dir/ -o v_out -DWIDTH_P=$(WIDTH_P) -DELS_P=$(ELS_P) -DRUNTIME=$(CYCLES_P)

run = ./v_out > transcript

.SILENT:
check = grep "ERROR" transcript | wc -l

.DEFAULT_GOAL := all
all:
	$(verilate)
	$(compile)
	$(run)
	echo Number of errors found:
	$(check)

clean:
	rm -r obj_dir/ transcript v_out
