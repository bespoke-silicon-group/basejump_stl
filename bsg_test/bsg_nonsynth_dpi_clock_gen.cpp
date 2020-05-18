#include <bsg_nonsynth_dpi_clock_gen.hpp>

using namespace bsg_nonsynth_dpi;

// Initializer for simuation time value in bsg_timekeeper
long long bsg_timekeeper::cur = 0;
// Initializer for priority queue in bsg_timekeeper
std::priority_queue<bsg_nonsynth_dpi_clock_gen, std::vector<bsg_nonsynth_dpi_clock_gen> > bsg_timekeeper::pq;

// next() determines the time of the next clock edge(s), updates cur
// to that value and then toggles the clock edge(s) that occur at that
// time. 
//
// NOTE: Verilator's eval() is not called here.
void bsg_timekeeper::next(){
        // Temporary storage for bsg_nonsynth_dpi_clock_gen objects
        // removed from the priority queue. If there are multiple
        // clock edges that need to be toggled, we need to remove all
        // of them from the priority queue before advancing time. 
        std::queue<bsg_nonsynth_dpi_clock_gen> temp;

        // Examine the head of the priority queue
        bsg_nonsynth_dpi_clock_gen &next = const_cast<bsg_nonsynth_dpi_clock_gen&>(pq.top());

        // Determine the next_timeval, as reported by the head of the
        // priority queue
        long long next_timeval = next.next_edge();

        // Toggle each each clock generator with an edge at the same
        // time as next_timeval. This handles the case where there are
        // multiple clock generators with coincident clock edges.
        do {
                next.tock();

                pq.pop();

                next = pq.top();

                temp.push(next);

        } while(next_timeval == next.next_edge());

        // Finally, advance the global simulation time
        advance(next_timeval);

        // Put all of the bsg_nonsynth_dpi_clock_gen objects back on
        // the priority queue
        while (!temp.empty()){
                pq.push(temp.front());
                temp.pop();
        }
}

// register_bsg_clock_gen instantiates a bsg_nonsynth_dpi_clock_gen
// class and adds it to the priority queue. cycle_time_p is the
// parameter of the verilog instantiated module, and hier is the
// modules hierarchy string that uniquely identifies it within the
// testbench scope.
int bsg_timekeeper::register_bsg_clock_gen(long long cycle_time_p, 
                                           const char * hierarchy){
        bsg_nonsynth_dpi_clock_gen *cg = 
                new bsg_nonsynth_dpi_clock_gen(cycle_time_p, hierarchy);

        pq.push(*cg);

        return pq.size();
}

// Constructor. cycle_time_p is the parameter of the verilog
// instantiated module, and hier is the modules hierarchy string that
// uniquely identifies it within the testbench scope.
//
// hier is used to set the DPI Scope so that the
// bsg_dpi_clock_gen_set_level DPI function within the correct
// corresponding verilog module for this object is called when
// toggling the clock edge.
bsg_nonsynth_dpi_clock_gen::bsg_nonsynth_dpi_clock_gen(const long long cycle_time_p, 
                                                       const char* hier) :
        clk(0),// To match the behavior of bsg_nonsynth_clock_gen, the
               // output clock is initially 0
        cycle_time_p(cycle_time_p){ 

        bool res;
        svScope prev;

        scope = svGetScopeFromName(hier);

        prev = svSetScope(scope);
        res = bsg_dpi_clock_gen_set_level(0);
        svSetScope(prev);

        next = bsg_timekeeper::current_timeval() + cycle_time_p / 2; // TODO Check that cycle_time_p is divisible by 2
}

// bsg_dpi_clock_gen_register registers a new clock generator verilog
// module. It is a call-back function that is exported to the verilog
// DPI interface and imported in bsg_nonsynth_dpi_clock_gen. 
int bsg_dpi_clock_gen_register(long long cycle_time_p, const char* hierarchy){
        return bsg_timekeeper::register_bsg_clock_gen(cycle_time_p, hierarchy);
}

// This function returns bsg_timekeeper::cur, and is required by
// verilator.
double sc_time_stamp () {
        return static_cast<double>(bsg_timekeeper::current_timeval());
}
