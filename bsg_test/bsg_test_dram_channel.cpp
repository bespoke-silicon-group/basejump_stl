#include <cstdio>
#include <cassert>
#include <map>
#include "bsg_test_dram_channel.hpp"

#ifdef DEBUG
#define pr_dbg(fmt, ...)                        \
    printf("[bsg_test_dram_channel]: " fmt, ##__VA_ARGS__)
#else
#define pr_dbg(fmt, ...)
#endif

using namespace std;

namespace bsg_test_dram_channel {
    std::map<parameter_t, Memory *> global_memories;
}

using namespace bsg_test_dram_channel;

extern "C" void * bsg_test_dram_channel_init(
    parameter_t id,
    parameter_t channel_addr_width_p,
    parameter_t data_width_p,
    parameter_t mem_els_p,
    parameter_t init_mem_p
    )
{
    assert(data_width_p % 8 == 0);
    Memory *memory =  new Memory(channel_addr_width_p, data_width_p, mem_els_p, init_mem_p);
    global_memories[id] = memory;
    return memory;
}

extern "C" byte_t bsg_test_dram_channel_get(
    void *handle,
    address_t addr
    )
{
    Memory *memory = reinterpret_cast<Memory*>(handle);
    pr_dbg("getting 0x%08llx   (%02x)\n", addr, memory->get(addr));
    return memory->get(addr);
}

extern "C" void bsg_test_dram_channel_set(
    void *handle,
    address_t addr,
    byte_t val
    )
{
    pr_dbg("setting 0x%08llx to %02x\n", addr, val);
    Memory *memory = reinterpret_cast<Memory*>(handle);
    memory->set(addr, val);
}
namespace bsg_test_dram_channel {
    Memory *bsg_test_dram_channel_get_memory(parameter_t id)
    {
        auto m = global_memories.find(id);
        if (m != global_memories.end()) {
            return m->second;
        } else {
            return nullptr;
        }
    }
}
