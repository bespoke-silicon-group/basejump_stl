// bsg_nonsynth_dpi_clock_gen is a drop-in replacement for
// bsg_nonsynth_clock_gen when using verilator, where delay statements
// (e.g. #1) are not valid.
//
// One of the frustrating parts of Verilator is that it "breaks" how
// we normally build testbenches. Our traditional approach is to use
// the bsg_nonsynth_clock_gen module and specify the clock period as a
// parameter. In Verilator, this is not possible because the module
// uses an unsupported delay statement. It's also more challenging
// (though not impossible) to have multiple clock domains.
//
// What I've done is create a drop-in replacement that is backed by a
// C++ API, called bsg_nonsynth_dpi_clock_gen . The user doesn't need
// to know the difference, they just use a different module name with
// the same parameters and include bsg_nonsynth_clock_gen_dpi.hpp
//
// The C++ API is callback based; When each clock-generator module is
// instantiated, it registers itself with the C++ object via an
// imported DPI function -- bsg_nonsynth_clock_gen_register. The
// bsg_timekeeper class tracks the global time (no different than
// normal verilator) and uses a priority queue to track when the next
// clock generator toggles. To advance time, the users calls
// bsg_timekeeper::next()
//
// This drop-in replacement supports multiple clock generators and
// can be embedded anywhere in the hierarchy.
`include "bsg_defines.v"

module bsg_nonsynth_dpi_clock_gen
  #(parameter longint cycle_time_p="inv"
    )
   (
    output bit o
    );

   int         id;
   string      hierarchy;
   
   import "DPI-C" function int bsg_dpi_clock_gen_register(input longint cycle_time_p, input string hierarchy);
   localparam longint cycle_time_lp = {32'b0, cycle_time_p[31:0]};
   
   if(cycle_time_p % 2)
     $fatal(1, "BSG ERROR (%M): cycle_time_p must be divisible by 2");
   
   if(cycle_time_p <= 0)
     $fatal(1, "BSG ERROR (%M): cycle_time_p must be greater than 0");
   
   initial begin
      $display("BSG INFO: bsg_nonsynth_dpi_clock_gen (initial begin)");
      $display("BSG INFO:     Instantiation: %M");
      $display("BSG INFO:     cycle_time_p  = %d", cycle_time_p);
      hierarchy = $sformatf("%m");
      id = bsg_dpi_clock_gen_register(cycle_time_lp, hierarchy);
   end

   export "DPI-C" function bsg_dpi_clock_gen_set_level;
   function bit bsg_dpi_clock_gen_set_level(bit clkval);
      o = clkval;
      
      return o;
   endfunction;
endmodule
