#pragma once
#include <vector>
#include <cstring>
#include <assert.h>
#include <cstdlib>
#include <cerrno>
#include <sys/mman.h>

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
            _id(id),
            _data(nullptr){

            _size = (data_width_p/8) * mem_els_p;
            _data = reinterpret_cast<byte_t*>(mmap(nullptr, _size, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANON, -1, 0));
            if (_data == MAP_FAILED) {
                fprintf(stderr, "Memory::Memory(): cannot allocate memory: %s\n", std::strerror(errno));
                std::exit(1);
            }

	    if (init_mem_p != 0)
	      std::memset(&_data[0], 0, _size);
        }

        virtual ~Memory() {
            if (_data != nullptr)
                munmap(_data, _size);
        }

        byte_t get(address_t addr) const {
            assert(addr < size());
            return _data[addr];
        }

        byte_t & get(address_t addr) {
            assert(addr < size());
            return _data[addr];
        }

        byte_t *get_ptr(address_t addr) {
            assert(addr < size());
            return &_data[addr];
        }

        void set(address_t addr, byte_t val) {
            assert(addr < size());
            _data[addr] = val;
        }

        byte_t & operator[](address_t addr) {
            assert(addr < size());
            return _data[addr];
        }

        byte_t operator[](address_t addr) const {
            assert(addr < size());
            return _data[addr];
        }

        address_t size() const {
            return _size;
        }

        parameter_t _channel_addr_width_p;
        parameter_t _data_width_p;
        parameter_t _mem_els_p;
        parameter_t _id;
        address_t   _size;
        byte_t     *_data;
    };

    Memory *bsg_mem_dma_get_memory(parameter_t id);
    void bsg_mem_dma_delete_memory(parameter_t id);
}
