// This header file contains the backing C++ implementation for the
// bsg_nonsynth_clock_gen_dpi module. 
//
// To use the bsg_nonsynth_clock_gen_dpi module, instantiate and
// parameterize one (or more) module instances and include this header
// file during c++ compilation.
//
// To run simulation and toggle clocks, users must call
// bsg_timkeeper::next(). This will advance time to the next time that
// a clock edge occurs and toggle all clock edges that should occur at
// that time (there could be more than one).
#ifndef __BSG_NONSYNTH_DPI_CLOCK_GEN_HPP
#define __BSG_NONSYNTH_DPI_CLOCK_GEN_HPP
#include <queue>
#include <svdpi.h>

#ifdef __cplusplus
extern "C" {
#endif
        extern unsigned char bsg_dpi_clock_gen_set_level(unsigned char clkval);
        int bsg_dpi_clock_gen_register(long long cycle_time_p, const char* hierarchy);
#ifdef __cplusplus
}
#endif

namespace bsg_nonsynth_dpi{

        // bsg_nonsynth_dpi_clock_gen is the C++ counterpart to the
        // verilog module (of the same name).
        // 
        // With bsg_timekeeper, they provide the same basic
        // functionality as the "traditional" bsg_nonsynth_clock_gen
        // module.
        // 
        // This class works by being instantiated during the execution
        // of intial of the bsg_nonsynth_clock_gen module. The initial
        // block calls the function bsg_dpi_clock_gen_register in
        // bsg_nonsynth_dpi_clock_gen.cpp, which instantiates this
        // class and adds the created instance to the bsg_timekeeper
        // priority queue.
        //
        // Users should not instantiate this class directly.
        class bsg_nonsynth_dpi_clock_gen{
                long long cycle_time_p; // Clock period (in picoseconds)
                long long next; // Time of next clock edge
                bool clk: 1; // Clock state

                svScope scope; // SystemVerilog DPI scope of the
                               // bsg_nonsynth_dpi_clock_gen verilog
                               // module that corresponds to an
                               // instance of this class

        public:
                // Constructor. cycle_time_p is the parameter of the
                // verilog instantiated module, and hier is the
                // modules hierarchy string that uniquely identifies
                // it within the testbench scope.
                //
                // hier is used to set the DPI Scope so that the
                // bsg_dpi_clock_gen_set_level DPI function within the
                // correct corresponding verilog module for this
                // object is called when toggling the clock edge.
                bsg_nonsynth_dpi_clock_gen(const long long cycle_time_p, 
                                           const char* hier);

                // Returns the time value the next edge will occur on.
                long long next_edge() const{
                        return next;
                }

                // Compares two bsg_nonsynth_dpi_clock_gen instances
                // and returns the one with the smaller next_edge
                // value. This is used by the priority queue in
                // bsg_timkeeper to find the next edge and toggle all
                // clocks that occur on that edge.
                bool operator<(const bsg_nonsynth_dpi_clock_gen& o) const{
                        return this->next_edge() > o.next_edge();
                }

                // tock() toggles the clock edge of this module. It
                // does not call eval(), in case multiple clock edges
                // are toggled at the same time.
                bool tock(){
                        bool res;

                        // Save the previous scope so that we can return to it.
                        svScope prev;
                        prev = svSetScope(scope);

                        // Toggle the internal clock value.
                        this->clk ^= 1;

                        // Update the next clock edge
                        this->next += cycle_time_p/2;

                        // Call the DPI function
                        // bsg_nonsynth_dpi_clock_gen in the
                        // corresponding module.
                        res = bsg_dpi_clock_gen_set_level(clk);

                        // Return to the previous scope
                        svSetScope(prev);

                        // Return the new clock value
                        return res;
                }
        };

        // bsg_timekeeper is responsible for... keeping track of
        // simulation time. 
        // 
        // In Verilator the C++ user program is responsible for
        // maintaining the global simulation timestamp through a
        // global variable and provides the current timestamp value
        // through the sc_time_stamp function.
        // 
        // Normally the user is responsible for providing an
        // sc_time_stamp function that returns a global
        // variable. However, to create drop-in replacements for
        // bsg_nonsynth_clock_gen the time variable is a static
        // variable in bsg_timekeeper, cur.
        //
        // The only way that simulation time can be advanced is by
        // instantiating a bsg_nonsynth_clock_gen_dpi module and then
        // calling bsg_timekeeper::next(). This will determine the
        // time of the next clock edge, advance the simulation
        // timestep to that value, and then toggle all necessary clock
        // edges (if more than one clock toggles at that time.
        //
        // The next clock edge (and corresponding
        // bsg_nonsynth_clock_gen_dpi class/module combo) is done with
        // a priority queue.
        class bsg_timekeeper{

                // Simulation time value
                static long long cur;

                // Priority queue used to determine the next clock
                // time.
                static std::priority_queue<bsg_nonsynth_dpi_clock_gen, 
                                           std::vector<bsg_nonsynth_dpi_clock_gen> > pq;

                // advance() updates cur to a new time
                // value and returns it. It is private so that
                // cur can only be updated by calling
                // next().
                static long long advance(long long timeval_new){
                        cur = timeval_new;
                        return cur;
                }

        public:
                // Accessor method for current_timeval
                static long long current_timeval(){
                        return cur;
                }

                // next() determines the time of the next clock
                // edge(s), updates cur to that time and then toggles
                // the clock edge(s).
                static void next();

                // register_bsg_clock_gen instantiates a
                // bsg_nonsynth_dpi_clock_gen class and adds it to the
                // priority queue. cycle_time_p is the parameter of
                // the verilog instantiated module, and hier is the
                // modules hierarchy string that uniquely identifies
                // it within the testbench scope.
                static int register_bsg_clock_gen(long long cycle_time_p, 
                                                  const char * hierarchy);
        };

}

// This function returns bsg_timekeeper::cur, and is required by
// verilator.
double sc_time_stamp ();

#endif
