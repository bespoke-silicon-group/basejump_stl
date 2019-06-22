/*
    test_bsg_float16.cpp

    This testbench testing Float16 division multithreadly with self-implemented float division. 
    And the testing program will be adapted for Berkely TestFloat after denormal condition is supported.
 */


#include<verilated.h>
#include<../obj_dir/Vbsg_fpu_div_float16.h>
#include<thread>


constexpr int thread_number_p = 16;

Vbsg_fpu_div_float16 *container[thread_number_p];


void performTesting(int bias){
    assert(bias < thread_number_p);
    // Reset
    Vbsg_fpu_div_float16 *dut = container[bias];

    dut->clk_i = 0;
    dut->reset_i = 1;
    dut->eval();
    dut->clk_i = 1;
    dut->eval();
    dut->clk_i = 0;
    dut->reset_i = 0;
    dut->yumi_i = 1;
    dut->eval();

    for(size_t i = bias ; i < 0xFFFFFFFF; i += thread_number_p){
        // extract dividend and divisor
        short dividend = (i & 0xFFFF0000) >> 16;
        short divisor = i & 0xFFFF;

        // Perform division

        dut->dividend_i = dividend;
        dut->divisor_i = divisor;
        dut->v_i = 1;
        dut->eval();
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

        short s_deno = !(dividend & 0x7C00);
        short d_deno = !(divisor & 0x7C00);

        if((s_deno | d_deno) & dut->unimplemented_o) continue;

        // NaN
        short result_is_nan = (dividend & 0x7C00) == 0x7C00 && (dividend & 0x3FF) != 0 // dividend is NaN
                            || (divisor & 0x7C00) == 0x7C00 && (divisor & 0x3FF) != 0  // divisor is NaN
                            || (dividend & 0x7C00) == 0x7C00 && (dividend & 0x3FF) == 0 && (divisor & 0x7C00) == 0x7C00 && (divisor & 0x3FF) == 0 // inf/inf
                            || (dividend & 0x7FFF) == 0 && (divisor & 0x7FFF) == 0; // 0/0
        if(result_is_nan && (dut->result_o & 0x7C00) == 0x7C00 && (dut->result_o & 0x3FF) != 0) 
            continue;
        
        // Inf

        short result_is_inf = (dividend & 0x7C00) == 0x7C00 && (dividend & 0x3FF) == 0 && (divisor & 0x7C00) != 0x7C00 | // inf / normal value
                            ((dividend & 0x7FFF) != 0 && (divisor & 0x7FFF) == 0); // normal value / 0

        if(result_is_inf && (dut->result_o & 0x7C00) == 0x7C00 && (dut->result_o & 0x3FF) == 0) continue;
        if((divisor & 0x7FFF) == 0 && dut->divisor_is_zero_o) continue;

        // Zero 

        if((dividend & 0x7FFF) == 0 && (divisor & 0x7FFF) != 0 && (dut->result_o & 0x7FFF) == 0) continue;

        unsigned int dividend_mantissa = (dividend & 1023) + 1024;
        unsigned int divisor_mantissa = (divisor & 1023) + 1024;

        dividend_mantissa <<= 11;
        unsigned short dividend_exponent = (dividend & 0x7C00) >> 10;
        unsigned short divisor_exponent = (divisor & 0x7C00) >> 10;

        unsigned short quotient_sign = (dividend ^ divisor) & 0x8000;

        short quotient_exponent = (dividend_exponent - divisor_exponent + 15);

        unsigned int quotient = dividend_mantissa / divisor_mantissa;
        int shifted = 0;

        if((quotient & 2048) == 0){
            quotient_exponent--;
        } else {
            quotient >>= 1;
        }

        // check overflow and underflow
        if(((quotient_exponent & 0xFFE0) == 0xFFE0 || (quotient_exponent == 0)) && dut->underflow_o) continue;
        if(((quotient_exponent & 0xFFE0) == 0x20 || (quotient_exponent == 0x1F)) && dut->overflow_o) continue;


        short quotient_expected =  quotient_sign | (quotient_exponent << 10) | quotient & 1023;

        if(quotient_expected == dut->result_o)
            continue;
        else{
            std::printf("dividend: %d divisor: %d quotient:%d quotient_hw:%d \n", dividend, divisor, quotient, dut->result_o);
            std::printf("%d: Error\n", bias);
            return;
        }
            
    }
}

int main(){
    std::thread *cpp_thread[thread_number_p];
    for(int i = 0; i < thread_number_p; ++i){
        container[i] = new Vbsg_fpu_div_float16();
        cpp_thread[i] = new std::thread(performTesting, i);
    }

    // wait
    for(auto &p : cpp_thread){
        p->join();
    }

    // cleaning if the program is not killed :)

    for(int i = 0; i < thread_number_p; ++i){
        delete container[i];
        delete cpp_thread[i];
    }
    
    return 0;
}