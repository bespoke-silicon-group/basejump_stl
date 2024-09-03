
`include "bsg_defines.sv"

module bsg_mem_2rw_sync_mask_write_bit #( parameter `BSG_INV_PARAM(width_p )
                         , parameter `BSG_INV_PARAM(els_p )
                         , parameter read_write_same_addr_p=0
                         , parameter addr_width_lp = `BSG_SAFE_CLOG2(els_p)
                         , parameter harden_p=1
                         , parameter disable_collision_warning_p=0
                         , parameter enable_clock_gating_p=0
                         )
  ( input                      clk_i
  , input                      reset_i

  , input [width_p-1:0]        a_data_i
  , input [width_p-1:0]        a_w_mask_i
  , input [addr_width_lp-1:0]  a_addr_i
  , input                      a_v_i
  , input                      a_w_i

  , input [width_p-1:0]        b_data_i
  , input [width_p-1:0]        b_w_mask_i
  , input [addr_width_lp-1:0]  b_addr_i
  , input                      b_v_i
  , input                      b_w_i

  , output logic [width_p-1:0] a_data_o
  , output logic [width_p-1:0] b_data_o
  );

   wire clk_lo;

   if (enable_clock_gating_p)
     begin
       bsg_clkgate_optional icg
         (.clk_i( clk_i )
         ,.en_i( a_v_i | b_v_i )
         ,.bypass_i( 1'b0 )
         ,.gated_clock_o( clk_lo )
         );
     end
   else
     begin
       assign clk_lo = clk_i;
     end

   bsg_mem_2rw_sync_mask_write_bit_synth
     #(.width_p(width_p)
       ,.els_p(els_p)
       ) synth
       (.clk_i (clk_lo)
       ,.reset_i
       ,.a_data_i
       ,.a_w_mask_i
       ,.a_addr_i
       ,.a_v_i
       ,.a_w_i
       ,.b_data_i
       ,.b_w_mask_i
       ,.b_addr_i
       ,.b_v_i
       ,.b_w_i
       ,.a_data_o
       ,.b_data_o
       );

`ifndef BSG_HIDE_FROM_SYNTHESIS

   always_ff @(negedge clk_lo)
     if (a_v_i | b_v_i) begin
       assert ((reset_i === 'X) || (reset_i === 1'b1) || (a_addr_i < els_p))
         else $error("Invalid address %x to %m of size %x (reset_i = %b, v_i = %b, clk_lo=%b)\n", a_addr_i, els_p, reset_i, a_v_i, clk_lo);

       assert ((reset_i === 'X) || (reset_i === 1'b1) || (b_addr_i < els_p))
         else $error("Invalid address %x to %m of size %x (reset_i = %b, v_i = %b, clk_lo=%b)\n", b_addr_i, els_p, reset_i, b_v_i, clk_lo);

       assert ((reset_i === 'X) || (reset_i === 1'b1) || (~(a_addr_i == b_addr_i && a_v_i && b_v_i && (a_w_i ^ b_w_i))) && !read_write_same_addr_p && !disable_collision_warning_p)
         else $error("%m: Attempt to read and write same address reset_i %b, %x <= %x (mask %x), %x <= %x (mask %x)",reset_i, a_addr_i,a_data_i,a_w_mask_i, b_addr_i, b_data_i, b_w_mask_i);

       assert ((reset_i === 'X) || (reset_i === 1'b1) || (~(a_addr_i == b_addr_i && a_v_i && b_v_i && (a_w_i & b_w_i))))
         else $error("%m: Attempt to write and write same address reset_i %b, %x <= %x (mask %x), %x <= %x (mask %x)",reset_i, a_addr_i,a_data_i,a_w_mask_i, b_addr_i, b_data_i, b_w_mask_i);
     end

   initial
     begin
        $display("## %L: instantiating width_p=%d, els_p=%d (%m)",width_p,els_p);

       	if (disable_collision_warning_p)
          $display("## %m %L: disable_collision_warning_p is set; you should not have this on unless you have broken code. fix it!\n");
     end

`endif

   
endmodule

`BSG_ABSTRACT_MODULE(bsg_mem_2rw_sync_mask_write_bit)

