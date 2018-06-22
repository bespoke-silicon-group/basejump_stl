run:
	vcs -f sv.include +v2k -R +lint=all -sverilog -full64 \
		-debug_pp -timescale=1ns/10ps

dve:
	dve -full64 -vpd vcdplus.vpd &
