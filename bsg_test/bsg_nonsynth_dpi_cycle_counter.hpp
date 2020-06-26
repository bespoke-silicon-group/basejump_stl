// This header file defines a C++ API that wraps the System Verilog
// DPI provided by bsg_nonsynth_dpi_cycle_counter.v
#ifndef __BSG_NONSYNTH_DPI_CYCLE_COUNTER
#define __BSG_NONSYNTH_DPI_CYCLE_COUNTER
#include <bsg_nonsynth_dpi.hpp>
#include <svdpi.h>
#include <cstring>
#include <cstdint>

// These are DPI functions provided by SystemVerilog compiler. If they
// are not found at link time, compilation will fail. See the
// corresponding function declarations in bsg_nonsynth_dpi_manycore.v
// for additional information.
extern "C" {
        extern unsigned char bsg_dpi_cycle_counter_is_window();
        extern void bsg_dpi_cycle_counter_read(svBitVecVal *);
}

namespace bsg_nonsynth_dpi{

        // dpi_cycle_counter is the C++ Object wrapper around the DPI calls
        // in bsg_nonsynth_dpi_cycle_counter.v
        //
        // This object must be destructed before $finish is called in
        // verilog.
        template <typename T>
        class dpi_cycle_counter : public dpi_base, public dpi_width<T>{
        public:
                dpi_cycle_counter(const std::string &hier)
                        : dpi_base(hier), 
                          dpi_width<T>(hier){}

                // is_window returns true if the interface is in a
                // valid time-window to call tx()
                bool is_window(){
                        bool o;
                        svScope prev;

                        prev = svSetScope(scope);
                        o = bsg_dpi_cycle_counter_is_window();
                        svSetScope(prev);

                        return o;
                }

                // read wraps the bsg_dpi_cycle_counter_read(output bit
                // [width_p-1:0] data_bo) DPI function exported by
                // bsg_nonsynth_dpi_from_fifo.v
                //
                // read MUST be called after the positive edge of the
                // input clock is evaluated. Failure will cause an
                // error and a call to $fatal in the verilog
                bool read(T& value){
                        svBitVecVal input[sizeof(T)/sizeof(svBitVecVal)];

                        prev = svSetScope(scope);
                        bsg_dpi_cycle_counter_read(input);
                        svSetScope(prev);
                        svToIntegral(input, value);

                        return 0;
                }
                
        };

}
#endif
