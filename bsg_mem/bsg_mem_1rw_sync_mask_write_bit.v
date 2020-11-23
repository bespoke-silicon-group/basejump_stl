// MBT 11/9/2014
//
// Synchronous 1-port ram.
// Only one read or one write may be done per cycle.

`include "bsg_defines.v"

module bsg_mem_1rw_sync_mask_write_bit #(
  parameter width_p=-1
  , parameter els_p=-1
  , parameter latch_last_read_p=0
  , parameter enable_clock_gating_p=0
  , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
) (input   clk_i
    , input reset_i
    , input [`BSG_SAFE_MINUS(width_p, 1):0] data_i
    , input [addr_width_lp-1:0] addr_i
    , input v_i
    , input [`BSG_SAFE_MINUS(width_p, 1):0] w_mask_i
    , input w_i
    , output [`BSG_SAFE_MINUS(width_p, 1):0]  data_o
);

   wire clk_lo;

   if (enable_clock_gating_p)
     begin
       bsg_clkgate_optional icg
         (.clk_i( clk_i )
         ,.en_i( v_i )
         ,.bypass_i( 1'b0 )
         ,.gated_clock_o( clk_lo )
         );
     end
   else
     begin
       assign clk_lo = clk_i;
     end

   bsg_mem_1rw_sync_mask_write_bit_synth
     #(.width_p(width_p)
       ,.els_p(els_p)
       ,.latch_last_read_p(latch_last_read_p)
       ) synth
       (.clk_i (clk_lo)
       ,.reset_i
       ,.data_i
       ,.addr_i
       ,.v_i
       ,.w_mask_i
       ,.w_i
       ,.data_o
       );


   // synopsys translate_off

   always_ff @(negedge clk_lo)
     if (v_i === 1)
       assert ((reset_i === 'X) || (reset_i === 1'b1) || (addr_i < els_p))
         else $error("Invalid address %x to %m of size %x (reset_i = %b, v_i = %b, clk_lo=%b)\n", addr_i, els_p, reset_i, v_i, clk_lo);

   initial
     begin
        $display("## %L: instantiating width_p=%d, els_p=%d (%m)",width_p,els_p);
     end

  // synopsys translate_on

   
endmodule
