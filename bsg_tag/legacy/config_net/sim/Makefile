include ../../../cad/common/mk/cadenv.mk

GTECH_DIR = $(ICC_RELEASE)/packages/gtech/src_ver
GTECH_SIM_LIB = $(ICC_RELEASE)/packages/gtech/src_ver/gtech_lib.v

VCS_FLAGS = -o $@ +v2k +vc -sverilog -full64 -timescale=1ns/1ns +vcs+lic+wait +multisource_int_delays +neg_tchk +libext+.v+.vlib+.vh +incdir+../src

TESTBENCH = config_net_tb.v
HDL_SOURCE = $(GTECH_DIR)/GTECH_NAND2.v \
             ../../bsg_async/bsg_launch_sync_sync.v \
						 ../src/rNandMeta.v \
             ../src/config_node.v \
             ../src/relay_node.v \
             ../src/config_snooper.v \
             ./config_setter.v \
             ./config_file_setter.v \
             ./config_node_bind.v \
             ./config_snooper_bind.v \
						 ./$(TESTBENCH)

HDL_INSTALL = ../src/config_defs.v \
              ../src/config_utils.v \
              ../../bsg_async/bsg_launch_sync_sync.v \
              ../src/rNandMeta.v \
              ../src/config_node.v \
              ../src/relay_node.v \
              ../src/config_snooper.v \
              ./config_setter.v \
              ./config_file_setter.v \
              ./config_node_bind.v \
              ./config_snooper_bind.v

HDL_INSTALL_DIR = /homes/$(USER)/raw/crudo/src/parts/verilog/config_net

PY_INSTALL_DIR = /homes/$(USER)/raw/greenlight/module_tests/config_node/common

all: testfile testbench simv sim

install:
	cp ${HDL_INSTALL} ${HDL_INSTALL_DIR} 
	cp generate_tb.py ${PY_INSTALL_DIR} 

uninstall:
	rm -rf ${HDL_INSTALL_DIR}/*
	rm -rf ${PY_INSTALL_DIR}/generate_tb.py

clean:
	rm -rf simv \
         csrc \
         simv.daidir \
         .vcsmx_rebuild \
         config_spec.out \
         config_test.in \
         config_file_setter.in \
         config_probe.in \
         *.log \
         *.dump \
         *.vcd \
         ucli.key \
         $(TESTBENCH)

testfile:
	./generate_tb.py --spec config_spec.in \
                   --generate-tests config_test.in \
                   --number-of-tests 20

testbench: testfile
	./generate_tb.py --spec config_spec.in \
                   --read-tests config_test.in \
                   --testbench config_net_tb.v \
                   --create-setter-file config_file_setter.in \
                   --create-probe-file config_probe.in

simv: testbench $(HDL_SOURCE)
	$(VCS) $(VCS_FLAGS) $(HDL_SOURCE) 2>&1 | tee $@.log

sim: simv
	./simv +config-file-setter +config-node-bind +config-snooper-bind +cyclic-test 2>&1 | tee $@.log

dve:
	$(VCS_BIN)/dve -full64

%.echo:
	@echo '$*=$($*)'
