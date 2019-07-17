#include "verilated.h"
#include "../common/fpu_common.h"
#include "obj_dir/Vbsg_fpu_sqrt_wrapper.h"
#include <cstdio>

int main(int argc, char **argv){
    Verilated::commandArgs(argc, argv);
    Vbsg_fpu_sqrt_wrapper *dut = new Vbsg_fpu_sqrt_wrapper();

    dut->clk_i = 0;
    dut->reset_i = 0;
    dut->v_i = 0; 
    dut->yumi_i = 1; 
    dut->opr_i = 0;

    dut->eval();

    dut->clk_i = 1;
    dut->reset_i = 1;
    dut->eval();

    dut->clk_i = 0;
    dut->reset_i = 0;
    dut->eval();
    //uint32_t i = 8393626;
    for(int j = 1; j < 255; ++j){
        for(int i = 0; i < (1 << 23); ++i){
            uint32_t ops_i = (j << 23) | i;
            float example = i2f(ops_i);
            dut->opr_i = ops_i;
            dut->v_i = 1;
            dut->clk_i = 1;
            dut->eval();

            dut->v_i = 0;
            dut->clk_i = 0;
            dut->eval();

            while(dut->v_o == 0){
                dut->clk_i = 1;
                dut->eval();
                dut->clk_i = 0;
                dut->eval();
            }
            float srt = sqrt(example);
            if (srt != i2f(dut->result_o)){
                std::printf("error: %d :cpp:%f, %d; cal: %f, %d\n", ops_i, sqrt(example),f2i(sqrt(example)), i2f(dut->result_o), dut->result_o);
                break;
            }
            dut->clk_i = 1;
            dut->eval();
            dut->clk_i = 0;
            dut->eval();
        }
        std::printf("j = %d done.\n",j);
    }
    

    

    return 0;
}