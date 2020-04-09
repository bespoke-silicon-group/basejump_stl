#include <cstdio>
#include <queue>
#include <vector>
#include <iostream>
// Verilator / DPI Headers
#include <svdpi.h>
#include <verilated.h>
#include <bsg_nonsynth_intf.hpp>
using namespace bsg_nonsynth_intf;
// Verilator-Generated Headers
#include <Vtop.h>

// This clock generator work is initial work to get a
// bsg_nonsynth_clkgen-like interface in verilator. It's ugly at the
// moment, so please ignore it.
class bsg_clk_gen;

class bsg_time{
        static std::vector<bsg_clk_gen> gens;
        static double timeval;
public:
        static double incr(double incr){
                return timeval += incr;
        }

        static double time(){
                return timeval;
        }

        static bsg_clk_gen& get(int id){
                return gens[id];
        }

        static int add(bsg_clk_gen &cg){
                int id = gens.size();
                gens.push_back(cg);
                return id;
        }
};
double bsg_time::timeval = 0.0d;
std::vector<bsg_clk_gen> bsg_time::gens = std::vector<bsg_clk_gen>();

// Called by $time in Verilog
double sc_time_stamp () {
        return bsg_time::time();
}

class bsg_clk_gen{
        double cycle_time_p;
        bool clk: 1;
public:
        bsg_clk_gen(const double cycle_time_p) : cycle_time_p(cycle_time_p) , clk(1){}

        bool tick(){
                bsg_time::incr(cycle_time_p/2);
                return clk ^= 1;
        }
};

unsigned char bsg_nonsynth_clock_gen_tick(int id){
        return bsg_time::get(id).tick();
}

// Register a new clock generator
int bsg_nonsynth_clock_gen_init(double cycle_time_p){
        bsg_clk_gen *cg = new bsg_clk_gen(cycle_time_p);
        bsg_time::add(*cg);
}

int main(int argc, char** argv) {
        Verilated::commandArgs(argc, argv);

        // Instantiation of module
        Vtop *top = new Vtop;

        // Uncomment this to debug the module hierarchy
        // Verilated::internalsDump();

        svScope scope;
        scope = svGetScopeFromName("TOP.top");
        svSetScope(scope);

        // Run the intial blocks with eval(). This must happen before
        // the fifo interfaces are constructed
        top->eval();

        // There must be some way to "pass" these functions by only
        // passing/setting the scope but I can't figure it
        // out. Therefore, they must be enumerated.
        fifo_to_dpi<unsigned int> *f2d = 
                new fifo_to_dpi<unsigned int>(top->f2d_init, top->f2d_fini,
                                              top->f2d_debug,top->f2d_width,
                                              top->f2d_rx);
        dpi_to_fifo<unsigned int> *d2f = 
                new dpi_to_fifo<unsigned int>(top->d2f_init, top->d2f_fini,
                                              top->d2f_debug, top->d2f_width,
                                              top->d2f_tx);

        // debug(true) will cause BSG DBGINFO statments to be printed
        f2d->debug(false);
        d2f->debug(false);

        // Run for 100 Cycles to clear reset
        for(int i = 0; i < 100; ++i){
                top->tick();
                top->eval(); // Negedge Clk

                top->tick();
                top->eval(); // Posedge Clk
        }

        std::queue<int> queue;
        unsigned int input_val, output_val;
        // For 10 iterations, fill the attached FIFO and then empty
        // it. Track the values that are sent over DPI using a C++
        // queue
        bool enq = false, deq = false;
        for(int iter = 0; iter < 10; iter ++){
                enq = false;
                deq = false;
                // Send until FIFO is full
                do {
                        top->tick();
                        top->eval(); // Negedge Clk
                        top->tick();
                        top->eval(); // Posedge Clk

                        // Write a random value to the FIFO
                        input_val = rand();

                        if(enq = d2f->tx(input_val))
                                queue.push(input_val);
                }while(enq);

                // Drain FIFO until empty. Check each value. However,
                // since the last value wasn't accepted we must
                // continue writing it until it is accepted to avoid a
                // protocol violation.
                do {
                        top->tick();
                        top->eval(); // Negedge Clk
                        top->tick();
                        top->eval(); // Posedge Clk

                        // We have to continue transmitting until the
                        // last data of the FILL loop is consumed
                        if(!enq){
                                if(enq = d2f->tx(input_val))
                                        queue.push(input_val);
                        }

                        // Read the FIFO, and check each value
                        deq = f2d->rx(output_val);
                        if(deq && (output_val != queue.front())){
                                fprintf(stderr,
                                        "BSG ERROR: data mismatch! HW: %x, SW:%x\n",
                                        output_val, queue.front());
                                exit(1);
                        }

                        if (deq){
                                queue.pop();
                        }
                } while(deq);
        }
        if(!queue.empty()){
                printf("BSG ERROR: Software Queue is not Empty!\n");
        }
        printf("BSG INFO: Fill/Drain RW test passed\n");

        // Write and read 100 values while the FIFO is nearly empty
        unsigned int read = 0, written = 0;
        input_val = rand();
        while(read < 100){
                top->tick();
                top->eval(); // Negedge Clk
                top->tick();
                top->eval(); // Posedge Clk

                // Write a random value to the FIFO, and generate a new random value
                if(written < 100 && (enq = d2f->tx(input_val))){
                        queue.push(input_val);
                        input_val = rand();
                        written++;
                }

                deq = f2d->rx(output_val);
                if(deq && (output_val != queue.front())){
                        fprintf(stderr,
                                "BSG ERROR: data mismatch! HW: %x, SW:%x\n",
                                output_val, queue.front());
                        exit(1);
                }

                if(deq) {
                        queue.pop();
                        read++;
                }
        }
        if(!queue.empty()){
                printf("BSG ERROR: Software Queue is not Empty!\n");
        }
        printf("BSG INFO: Nearly-Empty RW test passed\n");

        // Write and read 100 values while the FIFO is nearly full
        enq = false;
        deq = false;

        // Send until FIFO is full
        do {
                top->tick();
                top->eval(); // Negedge Clk
                top->tick();
                top->eval(); // Posedge Clk

                // Write a random value to the FIFO
                input_val = rand();
                if(enq = d2f->tx(input_val))
                        queue.push(input_val);
        } while(enq);

        int was_acc = 1, read_suc = 0;

        enq = false;
        deq = false;
        was_acc = 0, read_suc = 0;
        written = 0; read = 0;
        // While the FIFO is nearly full, write/read 100 values
        while(read  < 100){
                top->tick();
                top->eval(); // Negedge Clk
                top->tick();
                top->eval(); // Posedge Clk

                // Write a random value to the FIFO
                if(written < 100 && (enq = d2f->tx(input_val))){
                        queue.push(input_val);
                        input_val = rand();
                        written++;
                }

                deq = f2d->rx(output_val);
                if(deq && (output_val != queue.front())){
                        fprintf(stderr,
                                "BSG ERROR: data mismatch! HW: %x, SW:%x\n",
                                output_val, queue.front());
                        exit(1);
                }

                if(deq) {
                        queue.pop();
                        read++;
                }
        }

        // Drain FIFO until empty. Check each value. However, since
        // the last value may not have been accepted we must continue
        // writing it until it is accepted to avoid a protocol
        // violation.
        do {
                top->tick();
                top->eval(); // Negedge Clk
                top->tick();
                top->eval(); // Posedge Clk

                deq = f2d->rx(output_val);
                if(deq && (output_val != queue.front())){
                        fprintf(stderr,
                                "BSG ERROR: data mismatch! HW: %x, SW:%x\n",
                                output_val, queue.front());
                        exit(1);
                }

                if(deq) {
                        queue.pop();
                }
        } while (deq);

        if(!queue.empty()){
                printf("BSG ERROR: Software Queue is not Empty!\n");
        }

        printf("BSG INFO: Nearly-Full RW test passed\n");
        printf("BSG INFO: All tests passed\n");

        top->tick();
        top->eval();

        top->tick();
        top->eval();

        top->tick();
        top->eval();

        top->tick();
        top->eval();

        top->tick();
        top->eval();

        top->tick();
        top->eval();

        // You must call delete to call the internal DPI function
        // fini() for each interface
        delete d2f;
        delete f2d;

        // Call the DPI Function finish() to call $finish
        top->finish();
        // Then, trigger the final blocks in Verilog
        top->final();
        return 0;
}
