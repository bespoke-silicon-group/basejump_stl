# FIXME:  set up VCS, should modified for different users.
include ../../../../bsg_cadenv/cadenv.mk
export BASEJUMP_STL_DIR=$(abspath ../../..)
INCDIR = +incdir+$(BASEJUMP_STL_DIR)/bsg_misc

PLI_OPTS = -P mypli.tab get_stim.c +acc
VCS_OP     +=  +vcs+vcdpluson -debug_access+all
VCS_DEFINES =
CC = gcc
CFLAGS = -g
SRC=unsigned.c
SRC1=signed.c

ifdef SIGN
VCS_DEFINES += +define+SIGN=$(SIGN)
endif
ifdef WIDTH
VCS_DEFINES += +define+WIDTH=$(WIDTH)
endif
ifdef BITS_PER_ITER
VCS_DEFINES += +define+BITS_PER_ITER=$(BITS_PER_ITER)
endif
ifdef ITERS
VCS_DEFINES += +define+ITERS=$(ITERS)
endif

vcs:	
	$(VCS) -full64 -sverilog $(VCS_OP)  -Mupdate -f sv.include -f divide.files $(LIB_OPTS) $(PLI_OPTS) $(VCS_DEFINES)
	#./simv +vcs+stop+232100
	./simv

xvcs:
	$(VCS) -full64 -sverilog -Mupdate -RI -line -f divide.files $(LIB_OPTS) $(PLI_OPTS)

test: $(SRC)
	$(CC) -o unsigned.o -c $^ $(CFLAGS) -lm -std=c99 -D ITERS=$(ITERS) -D WIDTH=$(WIDTH)
	$(CC) unsigned.o -o test
	./test

test1: $(SRC1)
	$(CC) -o signed.o -c $^ $(CFLAGS) -lm -std=c99 -D ITERS=$(ITERS) -D WIDTH=$(WIDTH)
	$(CC) signed.o -o test1
	./test1

clean:
	$(RM) -r csrc simv.daidir vcs.key simv  ucli.key  vcdplus.vpd s_output.txt u_output.txt u.txt s.txt
dve64:
	$(VCS_BIN)/dve -full64
gtk:
	$(VCS_BIN)/vpd2vcd vcdplus.vpd vcd
	gtkwave vcd
verify:
	egrep [0-9] u_expected.txt | diff -w u_output.txt -
#	egrep [0-9] s_expected.txt | diff -w s_output.txt -
