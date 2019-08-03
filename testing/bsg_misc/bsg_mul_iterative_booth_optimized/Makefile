verilator:
	verilator --Wno-fatal -I../../../bsg_misc/ \
	-I../../../bsg_misc/bsg_wallace_tree/ \
	-sv --cc \
	../../../bsg_misc/bsg_defines.v \
	../../../bsg_misc/bsg_mul_iterative_booth_optimized.v \
	-Gwidth_p=32 -Gstride_p=16 -Gcpa_stride_p=32 -Gdebug_p=0 \
	--top-module bsg_mul_iterative_booth_optimized \
	--clk clk_i \
	--exe ./bsg_test.cpp \
	-CFLAGS "-g -std=c++11" \
	-LDFLAGS "-lpthread"
	
	make -C obj_dir -f Vbsg_mul_iterative_booth_optimized.mk

	./obj_dir/Vbsg_mul_iterative_booth_optimized

clean:
	@rm -rf obj_dir