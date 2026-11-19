#include "bsg_nonsynth_dpi_clock_gen.hpp"
#include <algorithm>
#include <cassert>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <utility>
#include <vector>

static int scope_ids[3];
static svScope scope;
static std::vector<std::pair<int,int>> changes;
extern "C" svScope svGetScopeFromName(const char *name) {
    return &scope_ids[std::atoi(name)];
}
extern "C" svScope svSetScope(const svScope next) {
    svScope previous=scope; scope=next; return previous;
}
extern "C" unsigned char bsg_dpi_clock_gen_set_level(unsigned char level) {
    int id=static_cast<int*>(scope)-scope_ids;
    changes.emplace_back(id,level); return level;
}
int main(int argc,char **argv) {
    using bsg_nonsynth_dpi::bsg_timekeeper;
    assert(argc >= 2 && argc <= 4);
    std::vector<int> half_periods;
    for(int i=1;i<argc;++i) {
        assert(std::atoi(argv[i]) >= 2 && std::atoi(argv[i]) % 2 == 0);
        half_periods.push_back(std::atoi(argv[i])/2);
        char name[8];std::snprintf(name,sizeof(name),"%d",i-1);
        bsg_timekeeper::register_bsg_clock_gen(std::atoi(argv[i]),name);
    }
    changes.clear(); int steps=0;
    // Reference schedule from integer multiples of each half period, with
    // coincident edges compared without imposing arbitrary callback order.
    for(int t=1;t<=60;++t) {
        std::vector<std::pair<int,int>> expected;
        for(unsigned i=0;i<half_periods.size();++i)
            if(t%half_periods[i]==0) expected.emplace_back(i,(t/half_periods[i])%2);
        if(expected.empty())continue;
        bsg_timekeeper::next();
        assert(bsg_timekeeper::current_timeval()==t);
        std::sort(changes.begin(),changes.end());
        assert(changes==expected);changes.clear();++steps;
    }
    std::printf("PASS clocks=%zu steps=%d\n",half_periods.size(),steps);
}
