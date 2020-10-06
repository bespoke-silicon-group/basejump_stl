include ../../../bsg_cadenv/cadenv.mk

sim:
	vcs +v2k -R +lint=all,noSVA-UA,noSVA-NSVU,noVCDE \
		-sverilog -full64 -f sv.include +incdir+../../bsg_misc\
		-timescale=1ps/1ps +vcs+vcdpluson -l vcs.log\

dve:
	dve -full64 -vpd vcdplus.vpd &
