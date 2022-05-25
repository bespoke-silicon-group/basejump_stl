include ../../../../../bsg_cadenv/cadenv.mk

#SPICE_FILE=osc.sp edge-measure.sp
SPICE_FILE=fo4.sp

PROCESS_NODE=14
ifeq ($(SPICE_EXPLORER),)
$(error SPICE_EXPLORER must be defined)
endif

ifeq ($(HSPICE),)
$(error HSPICE must be defined)
endif


NUM_CORES=6
CYCLES=84

EDGE_MEASURE=$(foreach x,$(shell /usr/bin/seq $(CYCLES)),@.measure hi_phase$(x)@+TRIG v\(n0\) VAL='SUPPLY/2' FALL=$(x)@+TARG v\(n0\) VAL='SUPPLY/2' RISE=$(shell expr $(x) + 0)@.measure lo_phase$(x)@+TRIG v\(n0\) VAL='SUPPLY/2' RISE=$(x)@+TARG v\(n0\) VAL='SUPPLY/2' FALL=$(shell expr $(x) + 1))


SUPPLY_MV = 800

ALL_SUPPLY_MV = 800 600 400 375 350 325 300 200

all: $(SUPPLY_MV).run.tmp.ic0

sweep-voltage-all: $(foreach voltage,$(ALL_SUPPLY_MV),$(voltage).run.tmp.ic0)

view: $(SUPPLY_MV).run.tmp.ic0
	$(SPICE_EXPLORER) run.tmp.tr0

edge-measure.sp: Makefile
	echo $(EDGE_MEASURE) | sed s/\@/\\n/g > $@

%.run.tmp.sp: setup.$(PROCESS_NODE).sp $(SPICE_FILE)
	cat $^ | sed 's/supply=0.8/supply=0.$*/g' > $@

%.ic0: %.sp
	$(HSPICE) $< -mt $(NUM_CORES) | tee $<.out

clean:
	- rm *.ex.sp *.ic0 *.st0 *.sp.out *.gen *.rails *.pgm *.report *.all *.log.* *.tr0 *.pa0 *.log run.tmp.sp run.tmp.* edge-measure.sp *~
	- rm -rf run.tmp.pvadir

echo.%:
	@echo $* = $($*)
