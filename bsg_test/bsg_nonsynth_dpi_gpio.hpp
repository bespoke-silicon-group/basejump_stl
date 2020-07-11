#ifndef __BSG_NONSYNTH_DPI_GPIO_HPP
#define __BSG_NONSYNTH_DPI_GPIO_HPP
#include <svdpi.h>
#include <bsg_nonsynth_dpi.hpp>
#include <cstring>

extern "C" {
        // DPI Export function: Get the value at an index in the
        // gpio. Calls $fatal if an invalid index is accessed.
        extern bool bsg_dpi_gpio_get(int);

        // DPI Export function: Set the value at an index in the
        // gpio. Calls $fatal if an invalid index is accessed.
        extern bool bsg_dpi_gpio_set(int, bool);

        // Returns the width_p of the parameterized HDL module
        extern int bsg_dpi_width();
}

namespace bsg_nonsynth_dpi{
        // dpi_gpio is the C++ wrapper class for the
        // bsg_nonsynth_dpi_gpio verilog module.
        //
        // This module provides a GPIO interface for C/C++ code, using
        // DPI. This provides the ability to set/read pins from C/C++. 
        // 
        // Template Parameters:
        // 
        //   unsigned int W: Width of the GPIO input and output busses
        //
        // Superclasses are used to check template parameters at run
        // time against the corresponding verilog module.
        template <unsigned int W>
        class dpi_gpio : public dpi_base{

        public:

                // Constructor: Creates a dpi_gpio object. 
                // 
                // Arguments: 
                //   char *hierarchy: The string describing
                //     the instantiation of this the corresponding
                //     bsg_nonsynth_dpi_gpio verilog module in the
                //     testbench.
                dpi_gpio(const std::string &hierarchy)
                        : dpi_base(hierarchy)
                {
                        svScope prev;
                        int w;

                        prev = svSetScope(svGetScopeFromName(hierarchy.c_str()));
                        w = bsg_dpi_width();
                        svSetScope(prev);

                        if(W != w){
                                fprintf(stderr, "BSG ERROR: Template width of GPIO"
                                        "interface (%d) does not match declared"
                                        "width_p (%d) of verilog\n", W, w);
                                exit(1);
                        }

                }

                // bool get(unsigned int index, bool value): Get the value
                // of the output pin at the given index
                // 
                // Arguments: 
                //   unsigned int index: The index to read
                // Returns:
                //   The value read
                bool get(unsigned int index){
                        bool retval;
                        prev = svSetScope(scope);
                        retval = bsg_dpi_gpio_get(index);
                        svSetScope(prev);
                        return retval;
                }

                // bool set(unsigned int index, bool value): Set the value
                // of the output pin at the given index
                // 
                // Arguments: 
                //   unsigned int index: The index to write
                //   bool value: The value to write
                // Returns:
                //   The value that the output pin was set to
                bool set(unsigned int index, bool value){
                        bool retval;
                        prev = svSetScope(scope);
                        retval = bsg_dpi_gpio_set(index, value);
                        svSetScope(prev);
                        return retval;
                }
        };
}
#endif
