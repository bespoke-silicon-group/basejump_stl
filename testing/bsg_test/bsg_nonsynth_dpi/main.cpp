#include <cstdio>
#include <queue>
#include <vector>
#include <iostream>
// Verilator / DPI Headers
#include <svdpi.h>
#include <verilated.h>

// Verilator-Generated Headers
#include <Vtop.h>

// This clock generator work is initial work to get a
// bsg_nonsynth_clkgen-like interface in verilator. It's ugly at the moment, so please ignore it.
class bsg_clk_gen;

class bsg_time{
        static std::vector<bsg_clk_gen> gens;
        static double timeval;
public:
        static double step(double incr){
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
                bsg_time::step(cycle_time_p/2);
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
        svLogicVecVal input, output;
        scope = svGetScopeFromName("TOP.top");
        svSetScope(scope);

        // Run the intial blocks with eval()
        top->eval();
        // debug() will cause BSG DBGINFO statments to be printed
        top->debug(false);
        top->init();

        // Run for 100 Cycles to clear reset
        for(int i = 0; i < 100; ++i){
                top->tick();
                top->eval(); // Negedge Clk

                top->tick(); 
                top->eval(); // Posedge Clk
        }
        
        std::queue<int> queue;
        // For 10 iterations, fill the attached FIFO and then empty
        // it. Track the values that are sent over DPI using a C++
        // queue
        for(int iter = 0; iter < 10; iter ++){
                int incr = 0 , decr =0 ;
                // Send until FIFO is full
                do {
                        top->tick();
                        top->eval(); // Negedge Clk
                        top->tick(); 
                        top->eval(); // Posedge Clk
                
                        // Write a random value to the FIFO
                        input.aval = rand();
                        incr = top->tx(&input);
                        if(incr)
                                queue.push(input.aval);
                }while(incr);

                // Drain FIFO until empty. Check each value. However,
                // since the last value wasn't accepted we must
                // continue writing it until it is accepted to avoid a
                // protocol violation.
                do {
                        top->tick();
                        top->eval(); // Negedge Clk
                        top->tick(); 
                        top->eval(); // Posedge Clk
                
                        // We have to continue transmitting until the last
                        // data of the FILL loop is consumed
                        if(!incr){
                                incr = top->tx(&input);
                                if(incr)
                                        queue.push(input.aval);
                        }

                        // Drain the FIFO
                        decr = top->rx(&output);
                        if(decr && (output.aval != queue.front())){
                                fprintf(stderr, "BSG ERROR: data mismatch! HW: %x, SW:%x\n", output.aval, queue.front());
                                exit(1);
                        } else if (decr){
                                queue.pop();
                        }
                } while(decr);
        }
        printf("BSG INFO: FULL RW test passed\n");

        // Write and read 100 values while the FIFO is nearly empty
        int was_acc = 1, read_suc = 0;
        for(int tot_read = 0, tot_written = 0; tot_read  < 100; ){
                top->tick();
                top->eval(); // Negedge Clk
                top->tick(); 
                top->eval(); // Posedge Clk
                
                // Write a random value to the FIFO
                if(tot_written < 100){
                        if(was_acc)
                                input.aval = rand();
                        if(was_acc = top->tx(&input)){
                                queue.push(input.aval);
                                tot_written++;
                        }
                }

                read_suc = top->rx(&output);
                tot_read += read_suc;
                if(read_suc && (output.aval != queue.front())){
                        fprintf(stderr, "BSG ERROR: data mismatch! HW: %x, SW:%x\n", output.aval, queue.front());
                        exit(1);
                } else if (read_suc) {
                        queue.pop();
                }
        }
        printf("BSG INFO: Nearly-Empty RW test passed\n");

        // Write and read 100 values while the FIFO is nearly full
        int incr = 0 , decr =0 ;
        // Send until FIFO is full
        do {
                top->tick();
                top->eval(); // Negedge Clk
                top->tick(); 
                top->eval(); // Posedge Clk
                
                // Write a random value to the FIFO
                input.aval = rand();
                incr = top->tx(&input);
                if(incr)
                        queue.push(input.aval);
        }while(incr);

        was_acc = 0, read_suc = 0;
        for(int tot_read = 0, tot_written = 0; tot_read  < 100; ){
                top->tick();
                top->eval(); // Negedge Clk
                top->tick(); 
                top->eval(); // Posedge Clk
                
                // Write a random value to the FIFO
                if(tot_written < 100){
                        if(was_acc)
                                input.aval = rand();
                        if(was_acc = top->tx(&input)){
                                queue.push(input.aval);
                                tot_written++;
                        }
                }

                read_suc = top->rx(&output);
                tot_read += read_suc;
                if(read_suc && (output.aval != queue.front())){
                        fprintf(stderr, "BSG ERROR: data mismatch! HW: %x, SW:%x\n", output.aval, queue.front());
                        exit(1);
                } else if (read_suc) {
                        queue.pop();
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
                
                // We have to continue transmitting until the last
                // data of the FILL loop is consumed
                if(!incr){
                        incr = top->tx(&input);
                        if(incr)
                                queue.push(input.aval);
                }

                // Drain the FIFO
                decr = top->rx(&output);
                if(decr && (output.aval != queue.front())){
                        fprintf(stderr, "BSG ERROR: data mismatch! HW: %x, SW:%x\n", output.aval, queue.front());
                        exit(1);
                }
                queue.pop();
        }while(decr);

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

        top->fini();
        return 0;
}
