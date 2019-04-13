
all:
	verilator -sv -cc tb.v -I../../../bsg_misc -y ../../../bsg_misc -y ../../../bsg_test -Wno-fatal
	cd obj_dir; make -f Vtb.mk; cd ..
	g++ -I obj_dir -I/usr/local/share/verilator/include  /usr/local/share/verilator/include/verilated.cpp obj_dir/*.a verilator_top.cc -o foo
	./foo | tee out.log
	-grep MISMATCH out.log

clean:
	rm -rf obj_dir out.log

 
