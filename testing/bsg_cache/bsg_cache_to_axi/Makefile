#
#		Makefile
#

include ~/hb/bsg_cadenv/cadenv_uw.mk
VCS_HOME = $(VCSMX_RELEASE)
VLOGAN_MX = $(VCS_HOME)/bin/vlogan
VCS_MX = $(VCS_HOME)/bin/vcs

INCDIR = +incdir+$(abspath $(BSG_IP_CORES_DIR))/bsg_misc/
INCDIR += +incdir+$(abspath $(BSG_IP_CORES_DIR))/bsg_cache/

DESIGN_UNIT = -lib axi_bram_ctrl_v4_0_14

HIGHLIGHT = grep --color -E '^|Error|Warning|Implicit wire is used|Too few instance port connections|Port connection width mismatch|Width mismatch'

compile:
	$(VLOGAN_MX) -full64 +notimingchecks -Xcheck_p1800_2009=char \
		
