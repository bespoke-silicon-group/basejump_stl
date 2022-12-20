#
#		Makefile
#

export BASEJUMP_STL_DIR = $(abspath ../../..)
include $(BASEJUMP_STL_DIR)/../bsg_cadenv/cadenv.mk

HIGHLIGHT = grep --color -E '^|Error|Warning|Implicit wire is used|Too few instance port connections|Port connection width mismatch|Width mismatch'

INCDIR = +incdir+$(BASEJUMP_STL_DIR)/bsg_misc/

sim:
	vcs +v2k -R +lint=all -sverilog -full64 -f sv.include $(INCDIR) \
		-debug_pp -timescale=1ps/1ps +vcs+vcdpluson | $(HIGHLIGHT)

dve:
	dve -full64 -vpd vcdplus.vpd &

clean:
	rm -rf DVEfiles
	rm -rf csrc
	rm -rf simv.daidir simv.vdb
	rm -f ucli.key vcdplus.vpd simv cm.log *.tar.gz vcs.log
