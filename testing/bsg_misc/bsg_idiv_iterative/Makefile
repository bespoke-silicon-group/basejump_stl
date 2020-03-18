# FIXME:  set up VCS, should modified for different users.
include ../../../../bsg_cadenv/cadenv.mk

PLI_OPTS = -P mypli.tab get_stim.c +acc
VCS_OP     +=  +vcs+vcdpluson -debug_access+all
vcs:
	$(VCS) -full64 -sverilog $(VCS_OP)  -Mupdate -f divide.files $(LIB_OPTS) $(PLI_OPTS)
	#./simv +vcs+stop+232100
	./simv

xvcs:
	$(VCS) -full64 -sverilog -Mupdate -RI -line -f divide.files $(LIB_OPTS) $(PLI_OPTS)

clean:
	$(RM) -r csrc simv.daidir vcs.key simv  ucli.key  vcdplus.vpd
dve64:
	$(VCS_BIN)/dve -full64
