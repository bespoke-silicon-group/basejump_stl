include ../../../bsg_cadenv/cadenv.mk

ANALYSIS_OPTIONS = -full64
ANALYSIS_OPTIONS += -sverilog
ANALYSIS_OPTIONS += +incdir+../../bsg_misc

RUN_OPTIONS = -full64
RUN_OPTIONS += -R
RUN_OPTIONS += -debug_pp
RUN_OPTIONS += -lca
RUN_OPTIONS += +vcs+vcdpluson
RUN_OPTIONS += +vcs+vcdplusmemon

analyze:
	vlogan $(ANALYSIS_OPTIONS) -timescale=1ns/1ps +incdir+lpddr_verilog_model+../../bsg_dmc +define+den2048Mb+sg5+x16+FULL_MEM -f filelist.lst -l $@.log

run:
	vcs $(RUN_OPTIONS) -l $@.log testbench

dve:
	dve -full64 -vpd vcdplus.vpd &

clean:
	rm -rf *.log
	rm -rf analyze_*
	rm -rf *.vpd
	rm -rf simv*
	rm -rf csrc
	rm -rf ucli.key
	rm -rf DVEfiles
	rm -rf AN.DB
