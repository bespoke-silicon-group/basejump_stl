#ifndef __BSG_NONSYNTH_DPI_ROM_HPP
#define __BSG_NONSYNTH_DPI_ROM_HPP
#include <svdpi.h>
#include <bsg_nonsynth_dpi.hpp>
#include <cstring>

extern "C" {
        // DPI Export function: Get the value at an index in the
        // rom. Calls $fatal if an invalid index is accessed.
        extern svBitVecVal bsg_dpi_rom_get(int);
}

namespace bsg_nonsynth_dpi{

        // dpi_rom is the C++ wrapper class for the
        // bsg_nonsynth_dpi_rom verilog module.
        // 
        // Template Parameters:
        // 
        //   typename T: The C-type that this rom contains. While
        //     verilog may represent arbitrary bit-widths, C cannot,
        //     so this rom is restricted to C-types.
        //
        //   unsigned int N: Number of Elements in the ROM.
        //
        // Superclasses are used to check template parameters at run
        // time against the corresponding verilog module.
        template <typename T, unsigned int N>
        class dpi_rom : public dpi_base, 
                    public dpi_width<T>, 
                    public dpi_nels<N>{
        public:

                // Constructor: Creates a dpi_rom object. 
                // 
                // Arguments: 
                //   char *hierarchy: The string describing
                //     the instantiation of this the corresponding
                //     bsg_nonsynth_dpi_rom verilog module in the
                //     testbench.
                dpi_rom(const std::string &hierarchy)
                        : dpi_base(hierarchy),
                          dpi_width<T>(hierarchy),
                          dpi_nels<N>(hierarchy)
                {
                }

                // T operator[](unsigned int idx): Returns the value
                // at an index in the ROM
                // 
                // Arguments: 
                //   unsigned int idx: The index to read
                T operator[](unsigned int idx){
                        T o;
                        prev = svSetScope(scope);
                        auto output = bsg_dpi_rom_get(idx);
                        svSetScope(prev);
                        svToIntegral(&output, o);
                        return o;
                }
        };
}
#endif
