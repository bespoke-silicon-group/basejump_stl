export BASEJUMP_STL_DIR = ../../..

INCDIR = +incdir+$(BASEJUMP_STL_DIR)/bsg_misc
INCDIR += +incdir+$(BASEJUMP_STL_DIR)/bsg_noc
INCDIR += +incdir+$(BASEJUMP_STL_DIR)/bsg_dataflow

.PHONY: sim dve all

all: sim

sim:
	vcs -R +lint=all,noSVA-UA,noSVA-NSVU,noVCDE -sverilog -full64 -f sv.include $(INCDIR) \
		-debug_all -assert svaext -timescale=1ps/1ps +vcs+vcdpluson +vcs+loopreport -cm line+tgl -cm_dir cov
	urg -full64 -dir cov

dve:
	dve -full64 -vpd vcdplus.vpd &

clean:
	rm -rf DVEfiles
	rm -rf csrc
	rm -rf simv.daidir simv.vdb
	rm -f ucli.key vcdplus.vpd simv cm.log *.tar.gz
	rm -rf trace.tr
