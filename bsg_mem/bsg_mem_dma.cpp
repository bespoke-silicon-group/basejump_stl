#include <cstdio>
#include <cassert>
#include <map>
#include "bsg_mem_dma.hpp"

#ifdef DEBUG
#define pr_dbg(fmt, ...)                        \
    do { printf("[bsg_mem_dma]: " fmt, ##__VA_ARGS__); fflush(stdout); } while (0)
#else
#define pr_dbg(fmt, ...)
#endif

using namespace std;

namespace bsg_mem_dma {
    std::map<parameter_t, Memory *> global_memories;
}

using namespace bsg_mem_dma;

extern "C" void * bsg_mem_dma_init(
    parameter_t id,
    parameter_t channel_addr_width_p,
    parameter_t data_width_p,
    parameter_t mem_els_p,
    parameter_t init_mem_p
    )
{
    pr_dbg("id = %llu, addr_width_p=%llu, data_width_p=%llu, mem_els_p=%llu\n",
           id, channel_addr_width_p, data_width_p, mem_els_p);
    
    assert(data_width_p % 8 == 0);
    Memory *memory =  new Memory(channel_addr_width_p, data_width_p, mem_els_p, init_mem_p, id);
    global_memories[id] = memory;
    return memory;
}

extern "C" byte_t bsg_mem_dma_get(
    void *handle,
    address_t addr
    )
{
    Memory *memory = reinterpret_cast<Memory*>(handle);
    pr_dbg("id = %llu: getting 0x%08llx   (%02x)\n", memory->_id, addr, memory->get(addr));
    return memory->get(addr);
}

extern "C" void bsg_mem_dma_set(
    void *handle,
    address_t addr,
    byte_t val
    )
{
    Memory *memory = reinterpret_cast<Memory*>(handle);
    pr_dbg("id = %llu: setting 0x%08llx to %02x\n", memory->_id, addr, val);
    memory->set(addr, val);
}

namespace bsg_mem_dma {
    Memory *bsg_mem_dma_get_memory(parameter_t id)
    {
        auto m = global_memories.find(id);
        if (m != global_memories.end()) {
            return m->second;
        } else {
            return nullptr;
        }
    }
}
