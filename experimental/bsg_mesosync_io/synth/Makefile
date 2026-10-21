CAD_PATH        = ../../../cad/

include $(CAD_PATH)/common/mk/cadenv.mk

DW_LIB = /gro/cad/synopsys/pkg/pkg_2004-2007/dw/Z-2007.03/dw/sim_ver
VCS_OPTIONS += +incdir+$(CURDIR)/src
VPD = 1

include $(CAD_PATH)/flow/vcs/setup/vcs.mk
export DESIGN_NAME=bsg_mesosync_link

dc:
	dc_shell -f dc_scripts/dc_setup.tcl

dc-gui:
	dc_shell -gui

dct:
	dc_shell -topo -f dc_scripts/dc.tcl 2>&1 | tee synth.log

fm:
	fm_shell

synth:
	dc_shell -f dc_scripts/dc.tcl 2>&1 | tee synth.log

clean_dc:
	rm -rf ./rtl_link default.svf *.log alib-52 reports results unmapped/* mapped/* work MY_DESIGN_LIB *.rpt formality_svf *.syn *.pvl *.mr core_lib core_flattened_LIB 
