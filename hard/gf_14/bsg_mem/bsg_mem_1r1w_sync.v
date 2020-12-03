
`include "bsg_mem_1r1w_sync_macros.vh"

module bsg_mem_1r1w_sync
  #(parameter width_p=-1
    , parameter els_p=-1
    , parameter read_write_same_addr_p=0
    , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
    , parameter harden_p=1
    , parameter disable_collision_warning_p=0
    , parameter enable_clock_gating_p=0
  )
  (
    input clk_i
    , input reset_i
    
    , input w_v_i
    , input [addr_width_lp-1:0] w_addr_i
    , input [width_p-1:0] w_data_i

    , input r_v_i
    , input [addr_width_lp-1:0] r_addr_i
    
    , output logic [width_p-1:0] r_data_o
  );

  // TODO: Define more hardened macro configs here
  `bsg_mem_1r1w_sync_macro(32,92,1) else
    begin: notmacro
    bsg_mem_1r1w_sync_synth #(
      .width_p(width_p)
      ,.els_p(els_p)
      ,.read_write_same_addr_p(read_write_same_addr_p)
    ) synth (.*); 
  end

   //synopsys translate_off
   initial
     begin
        $display("## %L: instantiating width_p=%d, els_p=%d, read_write_same_addr_p=%d, harden_p=%d (%m)",width_p,els_p,read_write_same_addr_p,harden_p);
     end

   always_ff @(negedge clk_i)
     if (w_v_i)
       begin
          assert ((reset_i === 'X) || (reset_i === 1'b1) || (w_addr_i < els_p))
            else $error("Invalid address %x to %m of size %x\n", w_addr_i, els_p);

          assert ((reset_i === 'X) || (reset_i === 1'b1) || ~(r_addr_i == w_addr_i && w_v_i && r_v_i && !read_write_same_addr_p && !disable_collision_warning_p))
            else
              begin
                 $error("X'ing matched read address %x (%m)",r_addr_i);
              end
       end
   //synopsys translate_on


endmodule
