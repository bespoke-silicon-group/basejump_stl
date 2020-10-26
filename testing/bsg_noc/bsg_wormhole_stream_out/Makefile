export BASEJUMP_STL_DIR = ../../..

-include $(BASEJUMP_STL_DIR)/../bsg_cadenv/cadenv.mk

INCDIR = +incdir+$(BASEJUMP_STL_DIR)/bsg_misc
INCDIR += +incdir+$(BASEJUMP_STL_DIR)/bsg_noc

.PHONY: sim dve all

all: sim

trace.tr:
	python bsg_trace_gen.py > trace.tr

bsg_trace_rom.v: trace.tr
	python $(BASEJUMP_STL_DIR)/bsg_mem/bsg_ascii_to_rom.py trace.tr bsg_trace_rom > bsg_trace_rom.v

sim: bsg_trace_rom.v
	vcs -R +lint=all,noSVA-UA,noSVA-NSVU,noVCDE -sverilog -full64 -f sv.include $(INCDIR) \
		-debug_pp -assert svaext -timescale=1ps/1ps +vcs+vcdpluson +vcs+loopreport -cm line+tgl -cm_dir cov
	urg -full64 -dir cov
	rm trace.tr

dve:
	dve -full64 -vpd vcdplus.vpd &

clean:
	rm -rf DVEfiles
	rm -rf csrc
	rm -rf simv.daidir simv.vdb
	rm -f ucli.key vcdplus.vpd simv cm.log *.tar.gz
	rm -rf trace.tr
	rm -rf bsg_trace_rom.v
