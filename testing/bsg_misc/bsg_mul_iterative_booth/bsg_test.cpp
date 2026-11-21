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

constexpr int use_thread_p = 16;

Vbsg_mul_iterative_booth *container[use_thread_p];

void performTesting(int bias){
    Vbsg_mul_iterative_booth *dut = container[bias];

    // Initialize
    dut->clk_i = 0;
    dut->reset_i = 0;
    dut->opA_i = 0;
    dut->opB_i = 0;
    dut->signed_i = 0;
    dut->v_i = 0;
    dut->yumi_i = 1;

    dut->eval();

    dut->clk_i = 1;
    dut->reset_i = 1;
    dut->eval();

    dut->clk_i = 0;
    dut->reset_i = 0;
    dut->eval();

    for(int i = 0; i < 65536; ++i){
        short opA = i & 0xFFFF;
        for(int j = bias; j < 65536; j += use_thread_p){
            short opB = j & 0xFFFF;
            dut->opA_i = opA;
            dut->opB_i = opB;
            dut->signed_i = 1;
            dut->eval();

            dut->v_i = 1;
            dut->clk_i = 1;
            dut->eval();

            dut->clk_i = 0;
            dut->v_i = 0;
            dut->eval();

            while(!dut->v_o){
                dut->clk_i = 1;
                dut->eval();
                dut->clk_i = 0;
                dut->eval();
            }
            int res = dut->result_o;

            dut->clk_i = 1;
            dut->eval();
            dut->clk_i = 0;
            dut->eval();
            if(res != opA * opB){
                std::printf("Error!\n");
                std::printf("opA = %d, opB = %d res = %x\n", opA, opB, res);
                return;
            }
        }
        std::printf("From Thead %d: i = %d is tested.\n",bias, i);
    }
}

int main(int argc, char **argv){
    Verilated::commandArgs(argc, argv);

    std::thread *cpp_thread[use_thread_p];

    for(int i = 0; i < use_thread_p; ++i){
        container[i] = new Vbsg_mul_iterative_booth{};
        cpp_thread[i] = new std::thread(performTesting, i);
    }

    for(auto &p : cpp_thread){
        p->join();
    }

    // Free resource

    for(int i = 0 ; i < use_thread_p; ++i){
        delete container[i];
        delete cpp_thread[i];
    }
    return 0;
}