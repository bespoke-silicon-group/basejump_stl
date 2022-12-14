#include <stdlib.h>
#include <iostream>
#include <utility>
#include <string>
#include "Vtest_bsg.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

unsigned int main_time = 0;

double sc_time_stamp () {
   return main_time;
}

int main (int argc, char **argv) {

    std::cout << "\nVerilatorTB: Start of sim\n" << std::endl; 

    Verilated::commandArgs(argc, argv);

    Vtest_bsg* top = new Vtest_bsg;

    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;

    top->trace (tfp, 99);
    Verilated::mkdir("waveform");
    tfp->open("waveform/sim.vcd");

    top -> clk = 0;
    top -> v_i = 0;
    top -> w_i = 0;

    while (main_time < 1000 && !Verilated::gotFinish()) 
    { 
        main_time ++;
        top->eval();

        if(main_time == 16) {
          top -> v_i = 0x1;
          top -> w_i = 0x1;
         } 

        if(main_time >= 200) {
           top -> w_i = 0;
        }

        if(main_time >= 500) {
           top -> w_i = 0x1;
        }
    
        if(main_time >= 750) {
           top -> w_i = 0x0;
        }

        if(main_time >= 950) {
           top -> w_i = 0x0;
        }

        if (tfp) tfp -> dump(main_time);

        top->clk = top->clk ? 0 : 1;
    }

    top -> final();

    if (tfp) tfp -> close();

    delete top;

    exit(0);
}