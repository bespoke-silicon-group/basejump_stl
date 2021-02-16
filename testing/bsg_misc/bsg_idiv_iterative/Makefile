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
	$(RM) -r csrc simv.daidir vcs.key simv  ucli.key  vcdplus.vpd s_output.txt u_output.txt
dve64:
	$(VCS_BIN)/dve -full64
gtk:
	$(VCS_BIN)/vpd2vcd vcdplus.vpd vcd
	gtkwave vcd
verify:
	gcc -std=c99 -Wall -o unsigned unsigned.c
	gcc -std=c99 -Wall -o signed signed.c
	./unsigned
	./signed
	diff -w u_output.txt u_expected.txt
	diff -w s_output.txt s_expected.txt
verify.clean:
	$(RM) s_expected.txt signed u_expected.txt unsigned
