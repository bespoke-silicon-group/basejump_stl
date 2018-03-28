all:
	gcc ./mult.c ../common/*.c -o ./app -lm -I../common/
send:
	./app > trace_master_2.tr
	scp ./trace_master_2.tr dcjung@linux12.ee.washington.edu:/home/dcjung/ee477/module2/ee477-designs/toplevels/bsg_guts_fpu/testing/v
