main: veriator_compile 
	./obj_dir/Vbsg_fpu_sqrt_wrapper

veriator_compile:
	verilator -sv -Wno-fatal -cc \
	../../../bsg_misc/bsg_defines.v \
	../../../bsg_misc/bsg_adder_carry_save.v \
	../../../bsg_misc/bsg_sqrt_core.v \
	../../../bsg_fpu/bsg_fpu_pkg.v \
	../../../bsg_fpu/bsg_fpu_preprocess.v \
	../../../bsg_fpu/bsg_fpu_sqrt.v \
	./bsg_fpu_sqrt_wrapper.v \
	--exe ./bsg_fpu_sqrt_testing.cpp \
	./../common/fpu_common.c \
	--CFLAGS "-g" \
	--top-module bsg_fpu_sqrt_wrapper

	make -C obj_dir -f Vbsg_fpu_sqrt_wrapper.mk

clean:
	@rm -rf obj_dir

	
