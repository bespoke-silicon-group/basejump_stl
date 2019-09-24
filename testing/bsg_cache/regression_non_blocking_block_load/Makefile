#
# Makefile
#
include ../../../../bsg_cadenv/cadenv.mk
export BASEJUMP_STL_DIR = $(abspath ../../..)


INCDIR = +incdir+$(BASEJUMP_STL_DIR)/bsg_misc/
INCDIR += +incdir+$(BASEJUMP_STL_DIR)/bsg_cache/


HIGHLIGHT = grep --color -E '^|Fatal|Error|Warning|Implicit wire is used|Too few instance port connections|Port connection width mismatch|Width mismatch'


.PHONY: dve sim all clean

all: sim

TRACE_TR = trace.tr
TRACE_GEN_PY = trace_gen.py
TRACE_ROM = trace_rom

$(TRACE_TR): $(TRACE_GEN_PY)
	python $(TRACE_GEN_PY) > $(TRACE_TR)

sim: $(TRACE_TR)
	vcs +v2k -R +lint=all,noSVA-UA,noSVA-NSVU,noVCDE \
		-sverilog -full64 -f sv.include $(INCDIR) \
		-timescale=1ps/1ps +vcs+vcdpluson $(DEFINE) -l vcs.log\
		| $(HIGHLIGHT)

dve:
	dve -full64 -vpd vcdplus.vpd &

clean:
	rm -rf DVEfiles
	rm -rf csrc
	rm -rf simv.daidir simv.vdb
	rm -f ucli.key vcdplus.vpd simv cm.log *.tar.gz vcs.log
	rm -rf stack.info.*
	rm -f $(TRACE_TR)

