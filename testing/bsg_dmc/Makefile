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
ELABORATE_OPTIONS += +define+BSG_OSC_BASE_DELAY=1000
ELABORATE_OPTIONS += +define+BSG_OSC_GRANULARITY=50
ELABORATE_OPTIONS += -timescale=1ps/1ps
ELABORATE_OPTIONS += -assert svaext
#Enable below line for using non-synthesisable TB
ELABORATE_OPTIONS += +define+NONSYNTH_TB
ELABORATE_OPTIONS += +lint=TFIPC-L

# ui_clk period
# how to use: make elaborate UI_CLK_PRD=<desired clock period value>
# Note unit is in ps and default is 400MHz as seen below
UI_CLK_PRD = 2500
ELABORATE_OPTIONS += +define+UI_CLK_PERIOD=$(UI_CLK_PRD)

ELABORATE_OPTIONS += +define+WRITE_GAP_CYCLES=400 +define+CMD_GAP_CYCLES=400

RUN_OPTIONS =
#RUN_OPTIONS += +irritate_clk

BSG_TRACE_FILES := bsg_dmc_trace_rom.tr bsg_tag_boot_rom.tr
BSG_TRACE_ROMS  := ${BSG_TRACE_FILES:.tr=_rom.v}

bsg_dmc_trace_rom.tr:
	python bsg_dmc_trace_rom.py 0 > $@

%.v: %.tr
	../../bsg_mem/bsg_ascii_to_rom.py $< $* > $@

elaborate : bsg_dmc_trace_rom.v bsg_tag_boot_rom.v
	$(VCS_BIN)/vcs $(ELABORATE_OPTIONS) -l $@.$(UI_CLK_PRD).log -f filelist.lst
	touch $@

run: elaborate
	./simv $(RUN_OPTIONS)  -l $@.$(UI_CLK_PRD).log
	touch $@

dve: 
	$(VCS_BIN)/dve -full64 -vpd vcdplus.vpd &

clean:
	rm -rf elaborate* run*
	rm -rf *.log
	#rm -rf bsg_dmc_trace_rom.tr
	#rm -rf *_rom.v
	rm -rf *.vpd
	rm -rf vc_hdrs.h
	rm -rf simv*
	rm -rf csrc
	rm -rf ucli.key
	#rm -rf DVEfiles
	rm -rf AN.DB

CLK_SPEEDS := 100000 5000 2500 1250 1000

regression:
	$(foreach CLK_SPD, $(CLK_SPEEDS), make -B elaborate UI_CLK_PRD=$(CLK_SPD); make run UI_CLK_PRD=$(CLK_SPD);)
