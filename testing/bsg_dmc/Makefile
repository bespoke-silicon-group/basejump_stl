include ../../../bsg_cadenv/cadenv.mk


ELABORATE_OPTIONS = -full64
ELABORATE_OPTIONS += -sverilog
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
CLK_SPEEDS := 100 1000 1250 2500 5000 6250 62500

RUNS       := $(foreach CLK_SPEED_P, $(CLK_SPEEDS), \
                   run-$(CLK_SPEED_P))

RUN_OPTIONS =
#RUN_OPTIONS += +irritate_clk

BSG_TRACE_FILES := bsg_dmc_trace_rom.tr bsg_tag_boot_rom.tr
BSG_TRACE_ROMS  := ${BSG_TRACE_FILES:.tr=_rom.v}

bsg_dmc_trace_rom.tr:
	python bsg_dmc_trace_rom.py 0 > $@

%.v: %.tr
	../../bsg_mem/bsg_ascii_to_rom.py $< $* > $@

regression: run
	grep -r "Regression\ test\ passed\!" */run-*.log
	! grep -r "Regression\ test\ failed\!" */run-*.log

run: $(RUNS)
run-%: bsg_dmc_trace_rom.v bsg_tag_boot_rom.v
	mkdir run-$*;
	cd run-$* && \
        $(VCS_BIN)/vcs $(ELABORATE_OPTIONS) -l run-$*.log -f ../filelist.lst -R \
        +define+UI_CLK_PERIOD=$(word 1, $(subst -, ,$*))

dve-%:
	cd run-$* && \
        $(VCS_BIN)/dve -full64 -vpd vcdplus.vpd &

clean:
	rm -rf elaborate* run*
	rm -rf *.log
	rm -rf bsg_dmc_trace_rom.tr
	rm -rf *_rom.v
	rm -rf *.vpd
	rm -rf vc_hdrs.h
	rm -rf simv*
	rm -rf csrc
	rm -rf ucli.key
	rm -rf DVEfiles
	rm -rf AN.DB
