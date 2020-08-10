include ../../../bsg_cadenv/cadenv.mk

ANALYSIS_OPTIONS = -full64
ANALYSIS_OPTIONS += -sverilog
ANALYSIS_OPTIONS += +incdir+../../bsg_clk_gen
ANALYSIS_OPTIONS += +incdir+../../bsg_misc

ELABORATE_OPTIONS = -full64
ELABORATE_OPTIONS += -debug_pp
ELABORATE_OPTIONS += -lca
ELABORATE_OPTIONS += +vcs+vcdpluson
ELABORATE_OPTIONS += +vcs+vcdplusmemon

RUN_OPTIONS = 

analyze:
	$(VCS_BIN)/vlogan $(ANALYSIS_OPTIONS) -timescale=1ns/1ps +incdir+lpddr_verilog_model+../../bsg_dmc +define+den2048Mb+sg5+x16+FULL_MEM -f filelist.lst -l $@.log
	touch $@

elaborate: analyze
	$(VCS_BIN)/vcs $(ELABORATE_OPTIONS) -l $@.log testbench
	touch $@

run: elaborate
	./simv $(RUN_OPTIONS) -l $@.log
	touch $@

dve: run
	$(VCS_BIN)/dve -full64 -vpd vcdplus.vpd &

clean:
	rm analyze elaborate run
	rm -rf *.log
	rm -rf analyze_*
	rm -rf *.vpd
	rm -rf simv*
	rm -rf csrc
	rm -rf ucli.key
	rm -rf DVEfiles
	rm -rf AN.DB
