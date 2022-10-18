# FIXME:  set up VCS, should modified for different users.
include ../../../../bsg_cadenv/cadenv.mk

PLI_OPTS = -P mypli.tab get_stim.c +acc
VCS_OP     +=  +vcs+vcdpluson -debug_access+all
vcs:
	$(VCS) -full64 -sverilog $(VCS_OP)  -Mupdate -f divide.files $(LIB_OPTS) $(PLI_OPTS) +define+SIGN=$(sign) \
	+define+UNSIGN=$(UNSIGN) +define+WIDTH=$(WIDTH) +define+BITS_PER_ITER=$(BITS_PER_ITER) +define+ITERS=$(ITERS)
	#./simv +vcs+stop+232100
	./simv

xvcs:
	$(VCS) -full64 -sverilog -Mupdate -RI -line -f divide.files $(LIB_OPTS) $(PLI_OPTS)

clean:
	$(RM) -r csrc simv.daidir vcs.key simv  ucli.key  vcdplus.vpd s_output.txt u_output.txt u.txt s.txt
dve64:
	$(VCS_BIN)/dve -full64
gtk:
	$(VCS_BIN)/vpd2vcd vcdplus.vpd vcd
	gtkwave vcd
verify:
	egrep [0-9] u_expected.txt | diff -w u_output.txt -
	egrep [0-9] s_expected.txt | diff -w s_output.txt -
