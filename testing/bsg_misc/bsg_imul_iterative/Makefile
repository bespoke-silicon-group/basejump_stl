# FIXME:  set up VCS, should modified for different users.
include /homes/shx089/cad/common/mk/cadenv.mk

VCS_OP     +=  +vcs+vcdpluson -debug_access+all

vcs:
	$(VCS) -full64 -sverilog  -Mupdate -f filelist.f $(VCS_OP)
	#./simv +vcs+stop+232100
	./simv

xvcs:
	$(VCS) -full64 -sverilog -Mupdate -RI -line -f filelist.f

clean:
	$(RM) -r csrc simv.daidir vcs.key simv  ucli.key  vcdplus.vpd
dve64:
	$(VCS_BIN)/dve -full64
