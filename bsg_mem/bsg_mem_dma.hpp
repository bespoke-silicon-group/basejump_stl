#pragma once
#include <vector>
#include <cstring>
#include <assert.h>
namespace bsg_mem_dma {
    using parameter_t = unsigned long long;
    using byte_t = unsigned char;
    using address_t = unsigned long long;

    class Memory {
    public:
        Memory(parameter_t channel_addr_width_p,
               parameter_t data_width_p,
               parameter_t mem_els_p,
	       parameter_t init_mem_p,
               parameter_t id):
            _channel_addr_width_p(channel_addr_width_p),
            _data_width_p(data_width_p),
            _mem_els_p(mem_els_p),
            _id(id) {

            parameter_t bytes = (data_width_p/8) * mem_els_p;
            _data.resize(bytes);
	    if (init_mem_p != 0)
	      std::memset(&_data[0], 0, _data.size());
        }

        byte_t get(address_t addr) const {
            assert(addr < _data.size());
            return _data[addr];
        }

        void set(address_t addr, byte_t val) {
            assert(addr < _data.size());
            _data[addr] = val;
        }

        byte_t & operator[](address_t addr) {
            assert(addr < _data.size());
            return _data[addr];
        }

        byte_t operator[](address_t addr) const {
            assert(addr < _data.size());
            return _data[addr];
        }

        std::vector<byte_t> _data;
        parameter_t _channel_addr_width_p;
        parameter_t _data_width_p;
        parameter_t _mem_els_p;
        parameter_t _id;
    };

    Memory *bsg_mem_dma_get_memory(parameter_t id);
}
