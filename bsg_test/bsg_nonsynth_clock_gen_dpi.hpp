#ifndef __BSG_NONSYNTH_CLOCK_GEN_DPI_HPP
#define __BSG_NONSYNTH_CLOCK_GEN_DPI_HPP
#include <queue>
#include <svdpi.h>
namespace bsg_nonsynth_dpi{

        class bsg_clock_gen{
                long long cycle_time_p;
                bool clk: 1;
                svScope scope;
                unsigned char (*set_clk_level)(unsigned char clkval);
                long long next_edge_ps;
        public:
                bsg_clock_gen(const long long cycle_time_p, const char* hier, unsigned char (*set_clk_level)(unsigned char));
                long long get_next_edge_ps() const{
                        return next_edge_ps;
                }
                bool operator<(const bsg_clock_gen& o) const{
                        return this->get_next_edge_ps() > o.get_next_edge_ps();
                }

                bool tock(){
                        svScope prev = svSetScope(scope);
                        bool res;

                        this->clk ^= 1;
                        this->next_edge_ps += cycle_time_p/2;

                        res = this->set_clk_level(clk);

                        svSetScope(prev);
                        return res;
                }
        };

        class bsg_timekeeper{ // This should be per TB
                static std::priority_queue<bsg_clock_gen, std::vector<bsg_clock_gen> > pq;
                static long long current_timeval_ps;
                static long long advance(long long timeval_new){
                        current_timeval_ps = timeval_new;
                        return current_timeval_ps;
                }

        public:
                static int tb_key;
                static long long current_timeval(){
                        return current_timeval_ps;
                }

                static void next();

                static int register_bsg_clock_gen(long long cycle_time_p, const char * hierarchy);
        };

}

double sc_time_stamp ();


#ifdef __cplusplus
extern "C" {
#endif
        int bsg_nonsynth_clock_gen_register(long long cycle_time_p, const char* hierarchy);
        extern unsigned char set_clk_level (unsigned char clkval);
#ifdef __cplusplus
}
#endif

#endif
