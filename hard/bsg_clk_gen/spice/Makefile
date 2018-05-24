include ../../../../cad/common/mk/cadenv.mk

SPICE_FILE=osc.sp
#SPICE_FILE=io.sp

PROCESS_NODE=180
ifeq ($(SPICE_EXPLORER),)
$(error SPICE_EXPLORER must be defined)
endif

ifeq ($(HSPICE),)
$(error HSPICE must be defined)
endif

# Xeon X3470
# 4 cores (3.2 Ghz) 3m45 1.46X
# 3 cores (3.2 Ghz) 4m7
# 2 cores (3.4 Ghz) 4m28 1.22X
# 1 core  (3.6 Ghz) 5m29 1.00X

NUM_CORES=3

all: run.tmp.ic0

view: run.tmp.ic0
	$(SPICE_EXPLORER) run.tmp.tr0

run.tmp.sp: setup.$(PROCESS_NODE).sp $(SPICE_FILE)
	cat $^ > run.tmp.sp

%.ic0: %.sp
	$(HSPICE) $< -mt $(NUM_CORES) | tee $<.out

clean:
	- rm *.ex.sp *.ic0 *.st0 *.sp.out *.gen *.rails *.pgm *.report *.all *.log.* *.tr0 *.pa0 *.log run.tmp.sp

