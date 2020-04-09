#ifndef __BSG_NONSYNTH_INTF_HPP
#define __BSG_NONSYNTH_INTF_HPP
#include <cstdio>
#include <svdpi.h>
#include <verilated.h>

namespace bsg_nonsynth_intf{
        template<typename T>
        class __intf{
                void (*init)() = nullptr;
                void (*fini)() = nullptr;
                int (*width)() = nullptr;

        public:
                void (*debug)(unsigned char) = nullptr;
                __intf(void (*init)(), void (*fini)(),
                       void(*debug)(unsigned char),
                       int (*width)()):
                        init(init), fini(fini), debug(debug), width(width)
                {
                        init();
                        if(width() != sizeof(T) * 8){
                                fprintf(stderr, "BSG ERROR: Declared type-width of "
                                        "interface (%d) does not match declared"
                                        "width_p (%d) of verilog", sizeof(T) * 8, width());
                                exit(1);
                        }

                }

                // The destructor is called when a stack-allocated
                // object goes out of scope, or when delete is called.
                ~__intf(){
                        fini();
                }
        };

        // fifo_to_dpi is the C++ Object wrapper around the DPI calls
        // in bsg_nonsynth_fifo_to_dpi.v
        template <typename T>
        class fifo_to_dpi: public  __intf<T>{
                unsigned char (*rx_f)(svLogicVecVal*) = nullptr;
        public:
                fifo_to_dpi(void (*init)(), void (*fini)(),
                            void(*debug)(unsigned char),
                            int (*width)(), unsigned char (*rx_f)(svLogicVecVal*))
                        : __intf<T>(init, fini, debug, width), rx_f(rx_f){
                }

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
        template <typename T>
        class dpi_to_fifo: public  __intf<T>{
                unsigned char (*tx_f)(const svLogicVecVal*) = nullptr;
        public:
                dpi_to_fifo(void (*init)(), void (*fini)(),
                            void(*debug)(unsigned char),
                            int (*width)(), unsigned char (*tx_f)(const svLogicVecVal*))
                        : __intf<T>(init, fini, debug, width), tx_f(tx_f){
                }

                unsigned char tx(const T& sent){
                        svLogicVecVal output;
                        output.aval = static_cast<decltype(output.aval)>(sent);
                        return tx_f(&output);
                }
        };
} // bsg_nonsynth_intf

#endif // __BSG_NONSYNTH_INTF_HPP
