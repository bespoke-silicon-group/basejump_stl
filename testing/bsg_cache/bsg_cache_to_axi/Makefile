#
#		Makefile
#

include ~/hb/bsg_cadenv/cadenv_uw.mk

VCS_MX_PATH = $(VCSMX_RELEASE)
VCS_MX = $(VCS_MX_PATH)/bin/vcs

INCDIR = +incdir+$(abspath $(BSG_IP_CORES_DIR))/bsg_misc/
INCDIR += +incdir+$(abspath $(BSG_IP_CORES_DIR))/bsg_cache/

HIGHLIGHT = grep --color -E '^|Error|Warning|Implicit wire is used|Too few instance port connections|Port connection width mismatch|Width mismatch'

sim:
	$(VCS_MX) +v2k -R +lint=all,noSVA-UA,noSVA-NSVU,noVCDE -sverilog \
		-full64 -f sv.include $(INCDIR) \
		-debug_pp -timescale=1ps/1ps +vcs+vcdpluson | $(HIGHLIGHT)
