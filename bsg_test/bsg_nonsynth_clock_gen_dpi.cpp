#include <bsg_nonsynth_clock_gen_dpi.hpp>

using namespace bsg_nonsynth_dpi;

long long bsg_timekeeper::current_timeval_ps = 0;
std::priority_queue<bsg_clock_gen, std::vector<bsg_clock_gen> > bsg_timekeeper::pq;


void bsg_timekeeper::next(){
        std::queue<bsg_clock_gen> temp;
        bsg_clock_gen &next = const_cast<bsg_clock_gen&>(pq.top());
        long long next_timeval = next.get_next_edge_ps();

        do {
                next.tock();
                pq.pop();
                next = pq.top();
                temp.push(next);
        } while(next_timeval == next.get_next_edge_ps());

        advance(next_timeval);

        while (!temp.empty()){
                pq.push(temp.front());
                temp.pop();
        }
}

// DPI Function exported by bsg_nonsynth_clock_gen.v
int bsg_timekeeper::register_bsg_clock_gen(long long cycle_time_p, const char * hierarchy){
        bsg_clock_gen *cg = new bsg_clock_gen(cycle_time_p, hierarchy, set_clk_level);
        pq.push(*cg); // This should be a struct with a Next-Time & a callback function that produces another struct. Or maybe a tuple.
        return pq.size();
}

bsg_clock_gen::bsg_clock_gen(const long long cycle_time_p, const char* hier, unsigned char (*set_clk_level)(unsigned char)) :
        set_clk_level(set_clk_level),
        cycle_time_p(cycle_time_p),
        clk(1){
        // TODO: Check that current_timeval is 0?

        this->scope = svGetScopeFromName(hier); // TODO: Check hierarchy exists.
        this->next_edge_ps = bsg_timekeeper::current_timeval() + cycle_time_p / 2; // TODO Check that cycle_time_p is divisible by 2
}

// Register a new clock generator
int bsg_nonsynth_clock_gen_register(long long cycle_time_p, const char* hierarchy){
        return bsg_timekeeper::register_bsg_clock_gen(cycle_time_p, hierarchy);
}
// Called by $time in Verilog
double sc_time_stamp () {
        return static_cast<double>(bsg_timekeeper::current_timeval());
}
