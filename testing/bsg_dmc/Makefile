include ../../../bsg_cadenv/cadenv.mk


ELABORATE_OPTIONS = -full64
ELABORATE_OPTIONS += -sverilog
ELABORATE_OPTIONS += +incdir+../../bsg_clk_gen
ELABORATE_OPTIONS += +incdir+../../bsg_misc
ELABORATE_OPTIONS += +incdir+../../bsg_tag
ELABORATE_OPTIONS += +incdir+../../bsg_dmc
ELABORATE_OPTIONS += +incdir+lpddr_verilog_model
ELABORATE_OPTIONS += -debug_pp
ELABORATE_OPTIONS += -sverilog
ELABORATE_OPTIONS += -lca
ELABORATE_OPTIONS += +vcs+vcdpluson
ELABORATE_OPTIONS += +vcs+vcdplusmemon
ELABORATE_OPTIONS += +define+den2048Mb+sg5+x16+FULL_MEM
ELABORATE_OPTIONS += -timescale=1ns/1ps
ELABORATE_OPTIONS += -assert svaext
#Enable below line for using non-synthesisable UVM TB
#ELABORATE_OPTIONS += +define+NONSYNTH_TB
ELABORATE_OPTIONS += +lint=TFIPC-L

RUN_OPTIONS =
#RUN_OPTIONS += +irritate_clk

BSG_TRACE_FILES := bsg_dmc_trace_rom.tr bsg_tag_boot_rom.tr
BSG_TRACE_ROMS  := ${BSG_TRACE_FILES:.tr=_rom.v}

bsg_dmc_trace_rom.tr:
	python bsg_dmc_trace_rom.py 0 > $@

%.v: %.tr
	../../bsg_mem/bsg_ascii_to_rom.py $< $* > $@

elaborate: bsg_dmc_trace_rom.v bsg_tag_boot_rom.v
	$(VCS_BIN)/vcs $(ELABORATE_OPTIONS) -l $@.log -f filelist.lst
	touch $@

run: elaborate
	./simv $(RUN_OPTIONS)  -l $@.log
	touch $@

dve: 
	$(VCS_BIN)/dve -full64 -vpd vcdplus.vpd &

clean:
	rm -rf analyze elaborate run
	rm -rf *.log
	rm -rf analyze_*
	rm -rf bsg_dmc_trace_rom.tr
	rm -rf *_rom.v
	rm -rf *.vpd
	rm -rf vc_hdrs.h
	rm -rf simv*
	rm -rf csrc
	rm -rf ucli.key
	#rm -rf DVEfiles
	rm -rf AN.DB
