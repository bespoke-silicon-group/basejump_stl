#include "verilated.h"
#include "obj_dir/Vbsg_mul_iterative_booth.h"

#include<ctime>
#include<cstdlib>
#include<thread>

template<typename T, size_t s = sizeof(T)> void dumpBits(const T * const p){
    const char *cp = reinterpret_cast<const char *>(p);
	for(size_t i = s; i > 0; --i){
		// dump cp[i]
		char tmp = cp[i - 1];
		for(int j = 7; j >=0; --j){
			std::printf("%u",(tmp & 0x80)>>7);
			tmp <<= 1;
		}
		std::printf(" ");
	}
	std::printf("\n");
}
int main(int argc, char **argv){
    Verilated::commandArgs(argc, argv);

    Vbsg_mul_iterative_booth *dut = new Vbsg_mul_iterative_booth{};

	// initialize
	dut->clk_i = 0;
	dut->reset_i = 0;
	dut->signed_i = 0;
	dut->opA_i = 0;
	dut->opB_i = 0;
	dut->v_i = 0;
	dut->yumi_i = 0;
	dut->eval();

	// reset
	dut->clk_i = 1;
	dut->reset_i = 1;
	dut->eval();
	dut->clk_i = 0;
	dut->reset_i = 0;

	int a = 0;
	int b = 0;

	dut->opA_i = a;
	dut->opB_i = b;
	dut->signed_i = 1;
	dut->eval();

	dut->v_i = 1;
	dut->clk_i = 1;
	dut->eval();
	dut->v_i = 0;
	dut->clk_i = 0;
	dut->eval();

	int latency = 0;
	while(!dut->v_o){
		dut->clk_i = 1;
		dut->eval();
		dut->clk_i = 0;
		dut->eval();
		++latency;
	}

	int64_t res = dut->result_o;

	std::printf("After %d cycle.\n", latency);

	if(res != int64_t(a) * int64_t(b)){
		std::printf("Error!\n");
		std::printf("opA = %d, opB = %d\n",a, b);
		std::printf("res = %llx\n", res);
		return 1;
	}

	return 0;

}