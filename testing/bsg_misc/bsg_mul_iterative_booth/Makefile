pipelined:
	verilator --Wno-fatal -I../../../bsg_misc/ \
	-I../../../bsg_misc/bsg_multiplier_compressor/ \
	-sv --cc \
	../../../bsg_misc/bsg_defines.v \
	../../../bsg_misc/bsg_mul_iterative_booth.v \
	-Gwidth_p=32 -Gstride_p=16 -Gcpa_stride_p=32 -Gdebug_p=0 -Gpipelined_p=1 \
	--top-module bsg_mul_iterative_booth \
	--clk clk_i \
	--exe ./pipelined.cpp \
	-CFLAGS "-g -std=c++11" \
	-LDFLAGS "-lpthread"

	make -C obj_dir -f Vbsg_mul_iterative_booth.mk

	./obj_dir/Vbsg_mul_iterative_booth

unpipelined:
	verilator --Wno-fatal -I../../../bsg_misc/ \
	-I../../../bsg_misc/bsg_multiplier_compressor/ \
	-sv --cc \
	../../../bsg_misc/bsg_defines.v \
	../../../bsg_misc/bsg_mul_iterative_booth.v \
	-Gwidth_p=32 -Gstride_p=32 -Gcpa_stride_p=16 -Gdebug_p=0 -Gpipelined_p=0 \
	--top-module bsg_mul_iterative_booth \
	--clk clk_i \
	--exe ./bsg_test.cpp \
	-CFLAGS "-g -std=c++11" \
	-LDFLAGS "-lpthread"
	
	make -C obj_dir -f Vbsg_mul_iterative_booth.mk

	./obj_dir/Vbsg_mul_iterative_booth

clean:
	@rm -rf obj_dir
