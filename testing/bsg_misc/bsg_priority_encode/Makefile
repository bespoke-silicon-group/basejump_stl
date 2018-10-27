#
#		Makefile
#

sim:
	vcs +v2k -R +lint=all -sverilog -full64 -f sv.include $(INCDIR) \
		-debug_pp -timescale=1ps/1ps +vcs+vcdpluson

dve:
	dve -full64 -vpd vcdplus.vpd &

clean:
	rm -rf DVEfiles
	rm -rf csrc
	rm -rf simv.daidir simv.vdb
	rm -f ucli.key vcdplus.vpd simv cm.log *.tar.gz
