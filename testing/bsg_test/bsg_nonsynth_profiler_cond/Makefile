include ../../../../bsg_cadenv/cadenv.mk

export BASEJUMP_STL_DIR = $(abspath ../../../)

INCDIR = +incdir+$(BASEJUMP_STL_DIR)/bsg_misc 


sim:
	vcs +v2k +lint=all,noSVA-UA,noSVA-NSVU,noVCDE -sverilog -full64 -f sv.include $(INCDIR) -debug_pp -timescale=1ps/1ps +vcs+vcdpluson -assert svaext
	# very important for the randomized code to work
	./simv -xlrm hier_inst_seed


dve:
	dve -full64 -vpd vcdplus.vpd &

view_profile:
	time ../../../bsg_test/bsg_nonsynth_profiler_analyzer.py --schema profile.schema --names profile.name --data profile.dat --debug_mapping --output=plot.pdf
	evince plot.pdf

clean:
	rm -rf DVEfiles
	rm -rf csrc
	rm -rf simv.daidir simv.vdb
	rm -f ucli.key vcdplus.vpd simv cm.log *.tar.gz vc_hdrs.h profile.name profile.dat profile.log plot.pdf



