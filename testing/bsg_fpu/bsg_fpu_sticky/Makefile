run:
	vcs -f sv.include +v2k -R +lint=all -sverilog -full64 \
		-debug_pp -timescale=1ns/10ps -l sim.log

dve:
	dve -full64 -vpd vcdplus.vpd &

clean:
	rm -r -f DVEfiles
	rm -r -f csrc
	rm -f sim.log
	rm simv
	rm -r -f simv.daidir 
	rm -f ucli.key
	rm -f vcdplus.vpd
