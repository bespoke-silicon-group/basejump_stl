#ifndef __BSG_NONSYNTH_DPI_FIFO_HPP
#define __BSG_NONSYNTH_DPI_FIFO_HPP
#include <cstring>
#include <svdpi.h>
#include <bsg_nonsynth_dpi.hpp>
#include <bsg_nonsynth_dpi_errno.hpp>

extern "C" {
        extern unsigned char bsg_dpi_fifo_tx(const svBitVecVal *);
        extern unsigned char bsg_dpi_fifo_rx(svBitVecVal *);
        extern unsigned char bsg_dpi_fifo_is_window(); 
}

namespace bsg_nonsynth_dpi{
        // dpi_from_fifo is the C++ Object wrapper around the DPI calls
        // in bsg_nonsynth_dpi_from_fifo.v
        //
        // This object must be destructed before $finish is called in
        // verilog.
        template <typename T>
        class dpi_from_fifo: public dpi_base, public dpi_width<T>{
        public:
                dpi_from_fifo(const std::string &hier)
                        : dpi_base(hier), 
                          dpi_width<T>(hier){
                }

                // is_window returns true if the interface is in a
                // valid time-window to call tx()
                bool is_window(){
                        bool o;
                        svScope prev;
                        prev = svSetScope(scope);
                        o = bsg_dpi_fifo_is_window();
                        svSetScope(prev);
                        return o;
                }

                // rx wraps the rx(output bit [width_p-1:0] data_o)
                // DPI function exported by bsg_nonsynth_dpi_from_fifo.v
                // 
                // To provide increased convenience, it unwraps the
                // svBitVecVal and returns the C-Type that matches
                // this FIFO's width.
                //
                // Data available on the producer FIFO interface is
                // returned in the read argument
                //
                // When valid data is available on the RTL interface
                // this function will return 1. When there is no valid data
                // available, this function will return 0.
                //
                // rx() MUST be called after the positive edge of the
                // input clock is evaluated. It MUST be called only
                // once per cycle. Failure will cause an error and a
                // call to $fatal in the verilog
                bool rx(T& read){
                        svBitVecVal input[sizeof(T)/sizeof(svBitVecVal)];
                        bool res;

                        prev = svSetScope(scope);
                        res = bsg_dpi_fifo_rx(input);
                        svSetScope(prev);
                        svToIntegral(input, read);
                        return res;
                }

                // try_rx wraps the rx(output bit [width_p-1:0] data_o) DPI
                // function exported by bsg_nonsynth_dpi_from_fifo.v with a more
                // programmer-friendly API
                // 
                // To provide increased convenience, it unwraps the svBitVecVal
                // and returns the C-Type that matches this FIFO's width.
                //
                // Data available on the producer FIFO interface is returned in
                // the read argument
                //
                // When the module is not in a valid clock window, it will
                // return BSG_NONSYNTH_DPI_NOT_WINDOW.
                //
                // When the module is in a valid clock window, but there is not
                // valid data it will return BSG_NONSYNTH_DPI_NOT_VALID.
                // 
                // When valid data is available on the RTL interface this
                // function will return BSG_NONSYNTH_DPI_SUCCESS and provide the
                // data in the read argument
                int try_rx(T& read){
                        svBitVecVal input[sizeof(T)/sizeof(svBitVecVal)];
                        prev = svSetScope(scope);

                        if(!bsg_dpi_fifo_is_window()){
                                svSetScope(prev);
                                return BSG_NONSYNTH_DPI_NOT_WINDOW;
                        }

                        if(!bsg_dpi_fifo_rx(input)){
                                svSetScope(prev);
                                return BSG_NONSYNTH_DPI_NOT_VALID;
                        }

                        svSetScope(prev);
                        svToIntegral(input, read);
                        return BSG_NONSYNTH_DPI_SUCCESS;
                }
        };

        // dpi_to_fifo is the C++ Object wrapper around the DPI calls
        // in bsg_nonsynth_dpi_to_fifo.v
        //
        // This object must be destructed before $finish is called in
        // verilog.
        template <typename T>
        class dpi_to_fifo: public dpi_base, public dpi_width<T>{
        public:
                dpi_to_fifo(const std::string &hier)

                        : dpi_base(hier),
                          dpi_width<T>(hier){                        
                }
                
                // is_window returns true if the interface is in a
                // valid time-window to call tx()
                bool is_window(){
                        bool res;
                        prev = svSetScope(scope);
                        res = bsg_dpi_fifo_is_window();
                        svSetScope(prev);
                        return res;
                }

                // tx wraps the tx(input logic [width_p-1:0] data_i) DPI
                // function exported by bsg_nonsynth_dpi_to_fifo.v
                // 
                // To provide increased convenience, this function wraps the
                // input argument data in the svBitVecVal type before sending it
                // to the DPI interface.
                //
                // If the consumer interface is ready this function will return
                // 1 to indicate that the consumer accepted the data. If the
                // consumer is not ready this function will return 0 to indicate
                // that the consumer did not accept the data.
                //
                // If the data is NOT accepted by the consumer FIFO, the host
                // C/C++ program MUST call this method again on the next cycle.
                //
                // If the data is not accepted by the consumer FIFO, the host
                // C/C++ program MUST call this this method with the same
                // arguments (i.e. data_i should remain constant across calls).
                //
                // tx() CAN ONLY be called after the positive edge of clk_i is
                // evaluated.
                bool tx(const T& data){
                        bool res;
                        svBitVecVal output[sizeof(T)/sizeof(svBitVecVal)];
                        svFromIntegral(data, output);
                        prev = svSetScope(scope);
                        res = bsg_dpi_fifo_tx(output);
                        svSetScope(prev);
                        return res;
                }

                // tx wraps the tx(input logic [width_p-1:0] data_i) DPI
                // function exported by bsg_nonsynth_dpi_to_fifo.v in a more
                // programmer-friendly API
                // 
                // To provide increased convenience, this function wraps the
                // input argument data in the svBitVecVal type before sending it
                // to the DPI interface.
                //
                // When the module is not in a valid clock window, it will
                // return BSG_NONSYNTH_DPI_NOT_WINDOW.
                //
                // When the module is in a valid clock window, but the consumer
                // is not ready this function will return
                // BSG_NONSYNTH_DPI_NOT_READY.
                // 
                // If the data is NOT accepted by the consumer FIFO
                // (i.e. BSG_NONSYNTH_DPI_NOT_READY is returned), the host C/C++
                // program MUST call this method again on the next cycle.
                //
                // If the data is not accepted by the consumer FIFO, the host
                // C/C++ program MUST call this this method with the same
                // arguments (i.e. data_i should remain constant across calls).
                //
                // If the consumer interface is ready this function will
                // BSG_NONSYNTH_DPI_SUCCESS indicate that the consumer
                // accepted the data.
                int try_tx(const T& data){
                        svBitVecVal output[sizeof(T)/sizeof(svBitVecVal)];
                        svFromIntegral(data, output);
                        prev = svSetScope(scope);

                        if(!bsg_dpi_fifo_is_window()){
                                svSetScope(prev);
                                return BSG_NONSYNTH_DPI_NOT_WINDOW;
                        }

                        if(!bsg_dpi_fifo_tx(output)){
                                svSetScope(prev);
                                return BSG_NONSYNTH_DPI_NOT_READY;
                        }

                        svSetScope(prev);
                        return BSG_NONSYNTH_DPI_SUCCESS;
                }
        };
}

#endif
