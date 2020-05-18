#include <Vtop.h>

#include <bsg_nonsynth_dpi_rom.hpp>
using namespace bsg_nonsynth_dpi;

#include <cstdio>
#include <queue>

// Verilator / DPI Headers
#include <svdpi.h>
#include <verilated.h>

int main(int argc, char** argv) {
        Verilated::commandArgs(argc, argv);

        // Instantiation of the top-level testbench module
        Vtop *top = new Vtop;

        // Uncomment internalsDump to debug the module hierarchy. This
        // is useful when you're trying to figure out the names of the
        // DPI functions you are trying to call.
        // Verilated::internalsDump();

        // Run the intial blocks with eval(). This must happen before
        // the fifo interfaces are constructed. It will also cause the
        // clock generators to register themselves.
        top->eval();

        dpi_rom<unsigned int, 4> *config = new dpi_rom<unsigned int, 4>("TOP.top.rom");
        for(int i =0 ; i < 4; ++i){
                printf("BSG INFO: Index: %d, Value: %x\n", i, (*config)[i]);
                if(i != (*config)[i]){
                        fprintf(stderr, "BSG ERROR: Incorrect value at index %d, expected %d\n", i, i);
                }
        }

        delete config;
        // Then, trigger the final blocks in Verilog
        top->final();
        return 0;
}
