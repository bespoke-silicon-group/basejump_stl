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
RUN_OPTIONS = 

BSG_TRACE_FILES := $(notdir $(wildcard *.tr))
BSG_TRACE_ROMS  := ${BSG_TRACE_FILES:.tr=_rom.v}

%_rom.v: %.tr
	../../bsg_mem/bsg_ascii_to_rom.py $< $*_rom > $@

elaborate: 
	$(VCS_BIN)/vcs $(ELABORATE_OPTIONS) -l $@.log -f filelist.lst testbench.v
	touch $@

run: elaborate
	./simv $(RUN_OPTIONS) -l $@.log
	touch $@

dve: 
	#run
	$(VCS_BIN)/dve -full64 -vpd vcdplus.vpd &

clean:
	rm -rf analyze elaborate run
	#rm -rf $(BSG_TRACE_ROMS)
	rm -rf *.log
	rm -rf analyze_*
	#rm -rf *.vpd
	rm -rf simv*
	rm -rf csrc
	rm -rf ucli.key
	#rm -rf DVEfiles
	rm -rf AN.DB
