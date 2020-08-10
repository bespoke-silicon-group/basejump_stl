#ifndef __BSG_NONSYNTH_DPI_HPP
#define __BSG_NONSYNTH_DPI_HPP
#include <string>
#include <cstring>
#include <cstdio>
#include <svdpi.h>


// These functions are provided by the SV Compiler. They are declared
// at global scope but svSetScope MUST be called to set the scope
// (verilog module instantiation) where the function are defined.
// 
// If the current scope does not contain these functions, calls to
// these functions will fail in the simulator.
extern "C" {
        extern void bsg_dpi_init();
        extern void bsg_dpi_fini();
        extern int bsg_dpi_width();
        extern int bsg_dpi_nels();
        extern void bsg_dpi_debug(unsigned char);
}

// The bsg_nonsynth_dpi namespace contains classes that are useful for
// wrapping DPI interfaces.
namespace bsg_nonsynth_dpi{

        // Convert a svBitVec val to an integral C-type.
        //
        // NOTE: This might be hyper verilator specific. I'm relying
        // on svBitVec being contiguously allocated to transfer data.
        template<typename T>
        inline void svToIntegral(const svBitVecVal *s, T &d){
                memcpy(&d, s, sizeof(T));
        }

        // Convert a svBitVec val to an integral C-type.
        //
        // NOTE: This might be hyper verilator specific. I'm relying
        // on svBitVec being contiguously allocated to transfer data.
        template<typename T>
        inline void svFromIntegral(const T &s, svBitVecVal *d){
                memcpy(d, &s, sizeof(T));
        }

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
        
        protected:
                svScope scope;
        public:
                svScope prev;
                dpi_base(const std::string &hier):
                        scope(svGetScopeFromName(hier.c_str()))
                {
                        if(!scope){
                                fprintf(stderr, "BSG ERROR: DPI Scope %s was not found\n", hier.c_str());
                                exit(1);
                        }
                        prev = svSetScope(scope);
                        bsg_dpi_init();
                        svSetScope(prev);
                }

                // debug() turns on runtime debug messages on if v ==
                // 1, and off if v == 0.
                void debug(unsigned char v){
                        prev = svSetScope(scope);
                        bsg_dpi_debug(v);
                        svSetScope(prev);
                }

                // The destructor is called when a stack-allocated
                // object goes out of scope, or when delete is called.
                //
                // It must be called before $finish is called in
                // Verilog.
                ~dpi_base(){
                        prev = svSetScope(scope);
                        bsg_dpi_fini();
                        svSetScope(prev);
                }
        };
        
        template<typename T>
        class dpi_width {
        public:
                dpi_width(const std::string &hier){
                        svScope prev;
                        int w;

                        prev = svSetScope(svGetScopeFromName(hier.c_str()));
                        w = bsg_dpi_width();
                        svSetScope(prev);

                        if(w != sizeof(T) * 8){
                                // TODO: We should throw an exception here...
                                fprintf(stderr, "BSG ERROR: Declared type-width of "
                                        "interface (%d) does not match declared"
                                        "width_p (%d) of verilog", sizeof(T) * 8, w);
                                exit(1);
                        }
                }

        };

        template<unsigned int N>
        class dpi_nels {
        public:
                dpi_nels(const std::string &hier){

                        svScope prev, scope = svGetScopeFromName(hier.c_str());
                        int n;

                        prev = svSetScope(scope);
                        n = bsg_dpi_nels();
                        svSetScope(prev);

                        if(n != N){
                                // TODO: We should throw an exception here...
                                fprintf(stderr, "BSG ERROR: Declared nels of "
                                        "interface (%d) does not match declared"
                                        "nels_p (%d) of verilog", N, n);
                                exit(1);
                        }
                }
        };


} // bsg_nonsynth_intf

#endif // __BSG_NONSYNTH_INTF_HPP
