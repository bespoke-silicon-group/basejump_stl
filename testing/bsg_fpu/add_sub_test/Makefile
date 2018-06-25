32_INPUT_ROM = add_sub_32_input.rom
32_OUTPUT_ROM= add_sub_32_output.rom

all: app testgen sim

testgen:
	./app
	echo "==== input ROM ===="
	cat $(32_INPUT_ROM)
	echo "==== output ROM ===="
	cat $(32_OUTPUT_ROM)

sim:
	vcs -f sv.include +v2k -R +lint=all -sverilog -full64 \
		-debug_pp -timescale=1ns/10ps -l sim.log \
		+define+ROM_SIZE=$(shell wc -l < $(32_INPUT_ROM))

app:
	g++ -o app ./app.cpp ../common/*.cpp \
		-I../common/ -lm -std=c++11
	

dve:
	dve -full64 -vpd vcdplus.vpd &

clean:
	rm -f app
	rm -rf DVEfiles
	rm -r csrc
	rm -f simv
	rm -f *.rom
	rm -f ucli.key
	rm -f sim.log
	rm -rf simv.daidir
	rm -f vcdplus.vpd
