#ifndef __BSG_NONSYNTH_DPI_HPP
#define __BSG_NONSYNTH_DPI_HPP
#include <cstdio>
#include <svdpi.h>
#include <verilated.h>

// The bsg_nonsynth_dpi namespace contains classes that are useful for
// wrapping DPI interfaces.
namespace bsg_nonsynth_dpi{

        // dpi_base wraps the init(), fini(), and debug() functions.
        // 
        // init() is called by constructing a dpi_base object, which
        // should be done after the verilog initial blocks are run.
        //
        // fini() is called by the destructor and should be called
        // before $finish is called in Verilog
        //
        // Debug can be called by the user to turn-on runtime
        // debugging.
        class dpi_base {
                void (*init)() = nullptr;
                void (*fini)() = nullptr;
        public:
                void (*debug)(unsigned char) = nullptr;
                dpi_base(void (*init)(), void (*fini)(),
                       void(*debug)(unsigned char)):
                        init(init), fini(fini), debug(debug)
                {
                        init();
                }

                // The destructor is called when a stack-allocated
                // object goes out of scope, or when delete is called.
                //
                // It must be called before $finish is called in
                // Verilog.
                ~dpi_base(){
                        if(Verilated::gotFinish()){
                                fprintf(stderr, "BSG ERROR: $finish called before "
                                        "bsg_dpi object was destructed");
                                exit(1);
                        }
                        
                        fini();
                }
        };
        
        template<typename T>
        class dpi_width {
                int (*width)() = nullptr;
        public:
                dpi_width(int (*width)()) : width(width){
                        if(width() != sizeof(T) * 8){
                                fprintf(stderr, "BSG ERROR: Declared type-width of "
                                        "interface (%d) does not match declared"
                                        "width_p (%d) of verilog", sizeof(T) * 8, width());
                                exit(1);
                        }
                }
        };

        // fifo_to_dpi is the C++ Object wrapper around the DPI calls
        // in bsg_nonsynth_fifo_to_dpi.v
        //
        // The constructor arguments: init(), debug(), and width() are
        // called during the constructor. fini() is called by the
        // superclass destructor.
        //        
        // This object must be destructed before $finish is called in
        // verilog.
        template <typename T>
        class fifo_to_dpi: public dpi_base, public dpi_width<T>{
                unsigned char (*rx_f)(svLogicVecVal*) = nullptr;
        public:
                fifo_to_dpi(void (*init)(), void (*fini)(),
                            void(*debug)(unsigned char),
                            int (*width)(), unsigned char (*rx_f)(svLogicVecVal*))
                        : dpi_base(init, fini, debug), dpi_width<T>(width), rx_f(rx_f){
                }

                // rx wraps the rx(output logic [width_p-1:0] data_o)
                // DPI function exported by bsg_nonsynth_fifo_to_dpi.v
                // 
                // To provide increased convenience, it unwraps the
                // svLogicVecVal and returns the C-Type that matches
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
                unsigned char rx(T& read){
                        svLogicVecVal input;
                        unsigned char res;
                        res = rx_f(&input);
                        read = static_cast<T>(input.aval);
                        return res;
                }
        };

        // dpi_to_fifo is the C++ Object wrapper around the DPI calls
        // in bsg_nonsynth_dpi_to_fifo.v
        //
        // The constructor arguments: init(), debug(), and width() are
        // called during the constructor. fini() is called by the
        // superclass destructor.
        //        
        // This object must be destructed before $finish is called in
        // verilog.
        template <typename T>
        class dpi_to_fifo: public dpi_base, public dpi_width<T>{
                unsigned char (*tx_f)(const svLogicVecVal*) = nullptr;
        public:
                dpi_to_fifo(void (*init)(), void (*fini)(),
                            void(*debug)(unsigned char),
                            int (*width)(), unsigned char (*tx_f)(const svLogicVecVal*))
                        : dpi_base(init, fini, debug), dpi_width<T>(width), tx_f(tx_f){
                }

                // tx wraps the tx(input logic [width_p-1:0] data_i)
                // DPI function exported by bsg_nonsynth_dpi_to_fifo.v
                // 
                // To provide increased convenience, this function
                // wraps the input argument data in the svLogicVecVal
                // type before sending it to the DPI interface.

                // If the consumer interface is ready this function
                // will return 1 to indicate that the consumer
                // accepted the data. If the consumer is not ready
                // this function will return 0 to indicate that the
                // consumer did not accept the data.
                //
                // If the data is NOT accepted by the consumer FIFO,
                // the host C/C++ program MUST call this method again
                // on the next cycle.
                //
                // If the data is not accepted by the consumer FIFO,
                // the host C/C++ program MUST call this this method
                // with the same arguments (i.e. data_i should remain
                // constant across calls).
                //
                // tx() CAN ONLY be called after the positive edge of
                // clk_i is evaluated.
                unsigned char tx(const T& data){
                        svLogicVecVal output;
                        output.aval = static_cast<decltype(output.aval)>(data);
                        return tx_f(&output);
                }
        };
} // bsg_nonsynth_intf

#endif // __BSG_NONSYNTH_INTF_HPP
