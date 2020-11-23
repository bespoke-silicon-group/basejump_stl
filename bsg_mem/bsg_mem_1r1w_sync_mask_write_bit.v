// MBT 7/7/2016
//
// 1 read-port, 1 write-port ram
//
// reads are synchronous

`include "bsg_defines.v"

module bsg_mem_1r1w_sync_mask_write_bit #(parameter width_p=-1
                                        , parameter els_p=-1
                                        // semantics of "1" are write occurs, then read
                                        // the other semantics cannot be simulated on a hardened, non-simultaneous
                                        // 1r1w SRAM without changing timing.
                                        // fixme: change to write_then_read_same_addr_p
                                        , parameter read_write_same_addr_p=0
                                        , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
                                        , parameter harden_p=0
                                        , parameter disable_collision_warning_p=1
                                        , parameter enable_clock_gating_p=0
                                        )
   (input   clk_i
    , input reset_i

    , input                     w_v_i
    , input [`BSG_SAFE_MINUS(width_p, 1):0]       w_mask_i
    , input [addr_width_lp-1:0] w_addr_i
    , input [`BSG_SAFE_MINUS(width_p, 1):0]       w_data_i

    , input                      r_v_i
    , input [addr_width_lp-1:0]  r_addr_i

    , output logic [`BSG_SAFE_MINUS(width_p, 1):0] r_data_o
    );

   wire clk_lo;

   if (enable_clock_gating_p)
     begin
       bsg_clkgate_optional icg
         (.clk_i( clk_i )
         ,.en_i( w_v_i | r_v_i )
         ,.bypass_i( 1'b0 )
         ,.gated_clock_o( clk_lo )
         );
     end
   else
     begin
       assign clk_lo = clk_i;
     end

   bsg_mem_1r1w_sync_mask_write_bit_synth
     #(.width_p(width_p)
       ,.els_p (els_p  )
       ,.read_write_same_addr_p(read_write_same_addr_p)
       ,.harden_p(harden_p)
       ,.disable_collision_warning_p(disable_collision_warning_p)
       ) synth
       (.clk_i(clk_lo)
       ,.reset_i
       ,.w_v_i
       ,.w_mask_i
       ,.w_addr_i
       ,.w_data_i
       ,.r_v_i
       ,.r_addr_i
       ,.r_data_o
       );

   //synopsys translate_off

/*
   always_ff @(negedge clk_lo)
     begin
        if (reset_i!==1'b1 & (r_v_i | w_v_i))
          $display("@@ w=%b w_addr=%x w_data=%x w_mask=%x r=%b r_addr=%x (%m)",w_v_i,w_addr_i,w_data_i,w_mask_i,r_v_i,r_addr_i);
     end
 */

   always_ff @(posedge clk_lo)
     if (w_v_i===1)
       begin
          assert ((reset_i === 'X) || (reset_i === 1'b1) || (w_addr_i < els_p))
            else $error("Invalid address %x to %m of size %x (reset_i = %b, w_v_i = %b, clk_lo = %b)\n", w_addr_i, els_p, reset_i, w_v_i, clk_lo);

          assert ((reset_i === 'X) || (reset_i === 1'b1) || (~(r_addr_i == w_addr_i && w_v_i && r_v_i && !read_write_same_addr_p && !disable_collision_warning_p)))
            else
              begin
                 $error("%m: Attempt to read and write same address reset_i %b, %x <= %x (mask %x)",reset_i, w_addr_i,w_data_i,w_mask_i);
                 //$finish();
              end
       end

   initial
     begin
        $display("## %L: instantiating width_p=%d, els_p=%d, read_write_same_addr_p=%d harden_p=%d (%m)",width_p,els_p,read_write_same_addr_p, harden_p);
     end

   //synopsys translate_on

   
endmodule
