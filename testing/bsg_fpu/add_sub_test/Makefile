ifeq ($(WIDTH),)
	WIDTH = 32
endif

INPUT_ROM = add_sub_input.rom
OUTPUT_ROM = add_sub_output.rom

all: clean app testgen sim

testgen:
	./app $(WIDTH)
	echo "==== input ROM ===="
	cat $(INPUT_ROM)
	echo "==== output ROM ===="
	cat $(OUTPUT_ROM)

sim:
	vcs -f sv.include +v2k -R +lint=all -sverilog -full64 \
		-debug_pp -timescale=1ns/10ps -l sim.log \
		+define+ROM_SIZE=$(shell wc -l < $(INPUT_ROM))+WIDTH=$(WIDTH)

app:
	g++ -o app ./app.cpp ./AddSubTester.cpp ../common/*.cpp \
		-I../common/ -I./ -lm -std=c++11
	
dve:
	dve -full64 -vpd vcdplus.vpd &

clean:
	rm -f app
	rm -rf DVEfiles
	rm -rf csrc
	rm -f simv
	rm -f *.rom
	rm -f ucli.key
	rm -f sim.log
	rm -rf simv.daidir
	rm -f vcdplus.vpd
