#include "svdpi.h"
#include "svdpi_src.h"
#include <vector>
#include <cstdio>
#include <cassert>

#ifdef DEBUG
#define pr_dbg(fmt, ...)                        \
    printf("[bsg_test_dram_channel]: " fmt, ##__VA_ARGS__)
#else
#define pr_dbg(fmt, ...)
#endif

using namespace std;

namespace bsg_test_dram_channel {
    using parameter_t = unsigned long long;
    using byte_t = unsigned char;
    using address_t = unsigned long long;

    class Memory {
    public:
        Memory(parameter_t channel_addr_width_p,
               parameter_t data_width_p,
               parameter_t mem_els_p):
            _channel_addr_width_p(channel_addr_width_p),
            _data_width_p(data_width_p),
            _mem_els_p(mem_els_p) {

            parameter_t bytes = (data_width_p/8) * mem_els_p;
            _data.resize(bytes);
        }

        byte_t get(address_t addr) const {
            return _data[addr];
        }

        void set(address_t addr, byte_t val) {
            _data[addr] = val;
        }

        byte_t & operator[](address_t addr) {
            return _data[addr];
        }

        byte_t operator[](address_t addr) const {
            return _data[addr];
        }

    private:
        std::vector<byte_t> _data;
        parameter_t _channel_addr_width_p;
        parameter_t _data_width_p;
        parameter_t _mem_els_p;
    };
}

using namespace bsg_test_dram_channel;

extern "C" void * bsg_test_dram_channel_init(
    parameter_t channel_addr_width_p,
    parameter_t data_width_p,
    parameter_t mem_els_p
    )
{
    int bytes = data_width_p/8;

    assert(data_width_p % 8 == 0);

    Memory *memory =  new Memory(channel_addr_width_p, data_width_p, mem_els_p);

    memory->set(0x00000000, 0xbe);
    memory->set(0x00000001, 0xba);
    memory->set(0x00000002, 0xfe);
    memory->set(0x00000003, 0xca);

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
