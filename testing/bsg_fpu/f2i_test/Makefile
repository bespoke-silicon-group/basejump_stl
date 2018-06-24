testgen:
	g++ -o app ./app.cpp ../common/*.cpp \
		-I../common/ -lm -std=c++11
	./app
	echo "input file"
	more f2i_32_input.rom
	echo "output file"
	more f2i_32_output.rom

sim:
	vcs -f sv.include +v2k -R +lint=all -sverilog -full64 \
		-debug_pp -timescale=1ns/10ps -l sim.log

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
