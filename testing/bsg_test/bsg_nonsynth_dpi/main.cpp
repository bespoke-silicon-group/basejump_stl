// This is the testbench for the bsg_nonsynth_fifo_dpi.v and
// bsg_nonsynth_dpi_fifo.v modules in bsg_test, and the
// bsg_nonsynth_dpi.hpp associated header file.
//
// The top-level verilog file instantiates each module, and a
// bsg_fifo_1r1w_small_unhardened FIFO between the two interfaces.
//
// This testbench performs three tests. 
//   1. Fills and then Drains the FIFO 100 times
//   2. Fills the FIFO and then reads/writes 100 elements while nearly full
//   3. Empties the FIFO and then reads/writes 100 elements while nearly empty
//
// Error checking is done throughout the test to ensure that the data
// transmitted matches the data received, and that the FIFO protocol
// is followed.
// 
// bsg_nonsynth_dpi.hpp contains the C/C++ class-wrappers for the DPI
// interface. The classes are in the bsg_nonsynth_dpi namespace
//
// Clocks are generated by the bsg_nonsynth_clock_gen_dpi module in
// the bsg_nonsynth_clock_gen_dpi.v file. Time progresses by calling
// bsg_timekeeper::next(). See the relevant files for more information
// about clock operation

// Verilator-Generated Header. It is called Vtop.h because top.sv is
// the top-level verilog file.
#include <Vtop.h>

#include <bsg_nonsynth_dpi_clock_gen.hpp>
#include <bsg_nonsynth_dpi_fifo.hpp>
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

        // There must be some way to "pass" these functions by only
        // passing/setting the scope, or passing a reference to the
        // scope that they are in, but I can't figure it
        // out. Therefore, they must be enumerated.
        dpi_from_fifo<unsigned int> *f2d = 
                new dpi_from_fifo<unsigned int>("TOP.top.f2d_i");
        dpi_to_fifo<unsigned int> *d2f = 
                new dpi_to_fifo<unsigned int>("TOP.top.d2f_i");

        // debug(true) will cause BSG DBGINFO statments to be printed
        // for the relevant interface.
        f2d->debug(false);
        d2f->debug(false);

        // Advance 100 times to clear reset. Alternatively, the
        // testbench can provide a DPI call to read the top-level
        // reset value, or the FIFO interfaces can be used, etc, etc,
        // etc.
        for(int i = 0; i < 100; ++i){
                bsg_timekeeper::next();
                top->eval();
        }

        // For 1000 iterations, fill the attached FIFO and then empty
        // it. Track the values that are sent over DPI using a C++
        // queue. 
        std::queue<int> queue;
        unsigned int input_val, output_val;
        
        // enq tracks whether the consumer accepted the data (tx returns 1)
        // deq tracks whether the producer provided data (rx returns 1)
        bool enq = false, deq = false;
        for(int iter = 0; iter < 100; iter ++){
                enq = false;
                deq = false;

                // Send data until the FIFO is full (i.e. enq returned
                // from a call to tx() is false/0)
                do {
                        bsg_timekeeper::next();
                        top->eval();

                        // Check if the DPI-To-FIFO interface is in a
                        // window of the clock period for transmitting
                        if(d2f->is_window()){
                                // Write a random value to the FIFO
                                input_val = rand();

                                if(enq = d2f->tx(input_val))
                                        queue.push(input_val);
                        }
                }while(enq);

                // Drain FIFO until empty. Check each value. However,
                // since the last value wasn't accepted we must
                // continue writing it until it is accepted to avoid a
                // protocol violation.
                do {
                        bsg_timekeeper::next();
                        top->eval();

                        // We have to continue transmitting until the
                        // last data of the FILL loop is consumed
                        if(!enq & d2f->is_window()){
                                if(enq = d2f->tx(input_val))
                                        queue.push(input_val);
                        }

                        // Read the FIFO, and check each value
                        //
                        // Check if the FIFO-to-DPI interface is in a
                        // window of the clock period for receiving
                        if(f2d->is_window()){
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
                        }
                } while(deq);
        }

        if(!queue.empty()){
                printf("BSG ERROR: Software Queue is not Empty! Should be empty at this point...\n");
        }

        printf("BSG INFO: Fill/Drain RW test passed\n");

        // Write and read 100 values while the FIFO is nearly empty
        //
        // read is used to track how many elements have been read from the RTL FIFO
        // written is used to track how many elements have been written to the RTL FIFO
        unsigned int read = 0, written = 0;
        input_val = rand();
        while(read < 100){
                bsg_timekeeper::next();
                top->eval();

                // While we've written less than 100 values, Write a
                // random value to the FIFO, and generate a new random
                // value.
                // 
                // Before transmitting, Check if the DPI-To-FIFO
                // interface is in a window of the clock period for
                // transmitting
                if(written < 100 && d2f->is_window() && (enq = d2f->tx(input_val))){
                        queue.push(input_val);
                        input_val = rand();
                        written++;
                }

                // Read the FIFO, and check each value
                //
                // Check if the FIFO-To-DPI interface is in a
                // window of the clock period for receiving
                if(f2d->is_window()){
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
        }

        if(!queue.empty()){
                printf("BSG ERROR: Software Queue is not Empty!\n");
        }
        printf("BSG INFO: Nearly-Empty RW test passed\n");

        // Write and read 100 values while the FIFO is nearly full
        enq = false;
        deq = false;
        // Send data until the FIFO is full (i.e. enq returned during
        // from a call to tx() is false/0)
        do {
                bsg_timekeeper::next();
                top->eval();
                // Check if the DPI-To-FIFO interface is in a window
                // of the clock period for transmitting
                if(d2f->is_window()){

                        // Write a random value to the FIFO
                        input_val = rand();
                        if(enq = d2f->tx(input_val))
                                queue.push(input_val);
                }
        } while(enq);

        enq = false;
        deq = false;
        written = 0; read = 0;
        // While the FIFO is nearly full, write/read 100 values
        while(read  < 100){
                bsg_timekeeper::next();
                top->eval();

                // While we've written less than 100 values, Write a
                // random value to the FIFO, and generate a new random
                // value.
                // 
                // Before transmitting, Check if the DPI-To-FIFO
                // interface is in a window of the clock period for
                // transmitting
                if(written < 100 && d2f->is_window() && (enq = d2f->tx(input_val))){
                        queue.push(input_val);
                        input_val = rand();
                        written++;
                }
         
                // Read the FIFO, and check each value
                //
                // Check if the FIFO-to-DPI interface is in a window
                // of the clock period for receiving
                if(f2d->is_window()){
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
        }

        // Drain FIFO until empty. Check each value. However, since
        // the last value may not have been accepted we must continue
        // writing it until it is accepted to avoid a protocol
        // violation.
        do {
                bsg_timekeeper::next();
                top->eval();

                // Read the FIFO, and check each value
                //
                // Check if the FIFO-To-DPI interface is in a
                // window of the clock period for receiving
                if(f2d->is_window()){
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
                }
        } while (deq);

        if(!queue.empty()){
                printf("BSG ERROR: Software Queue is not Empty!\n");
        }

        printf("BSG INFO: Nearly-Full RW test passed\n");
        printf("BSG INFO: All tests passed\n");

        bsg_timekeeper::next();
        top->eval();

        bsg_timekeeper::next();
        top->eval();

        bsg_timekeeper::next();
        top->eval();

        bsg_timekeeper::next();
        top->eval();

        bsg_timekeeper::next();
        top->eval();

        bsg_timekeeper::next();
        top->eval();

        // You must call delete to call the internal DPI function
        // fini() for each interface
        delete d2f;
        delete f2d;

        // Then, trigger the final blocks in Verilog
        top->final();
        return 0;
}
