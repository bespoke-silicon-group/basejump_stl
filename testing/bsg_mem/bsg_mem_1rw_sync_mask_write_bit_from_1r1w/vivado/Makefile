.DEFAULT_GOAL := all
all:
	$(clean)
	source /tools/Xilinx/Vivado/2021.1/settings64.sh
	vivado -mode tcl -source script.tcl

clean:
	rm -r vivado*
