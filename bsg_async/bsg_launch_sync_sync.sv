// MBT 7/24/2014
// DWP 4/10/2025
// moved rp groups to asic

`include "bsg_defines.sv"

module bsg_launch_sync_sync #(parameter `BSG_INV_PARAM(width_p)
                              , parameter use_negedge_for_launch_p = 0
                              , parameter use_async_reset_p = 0
                              , parameter harden_p = 0)
   (input iclk_i
    , input iclk_reset_i
    , input oclk_i
    , input  [width_p-1:0] iclk_data_i
    , output [width_p-1:0] iclk_data_o // after launch flop
    , output [width_p-1:0] oclk_data_o // after sync flops
    );

`ifndef BSG_HIDE_FROM_SYNTHESIS

  initial
  begin
     $display("%m: instantiating blss of size %d",width_p);
  end
`endif

   logic [width_p-1:0] bsg_SYNC_LNCH_r, bsg_SYNC_1_r, bsg_SYNC_2_r;

   for (genvar i = 0; i < width_p; i++)
     begin : rof
       wire launch_clk = use_negedge_for_launch_p ? ~iclk_i : iclk_i;
       bsg_dff_reset #(.width_p(1)) launch
        (.clk_i(launch_clk)
         ,.reset_i(iclk_reset_i)
         ,.data_i(iclk_data_i[i])
         ,.data_o(bsg_SYNC_LNCH_r[i])
         );

       wire latch_reset = use_async_reset_p ? iclk_reset_i : 1'b0;
       bsg_sync_sync_async_reset_unit bss
        (.oclk_i(oclk_i)
         ,.iclk_reset_i(latch_reset)
         ,.iclk_data_i(bsg_SYNC_1_r[i])
         ,.oclk_data_o(bsg_SYNC_2_r[i])
         );
     end
   assign iclk_data_o = bsg_SYNC_LNCH_r;
   assign oclk_data_o = bsg_SYNC_2_r;

endmodule

`BSG_ABSTRACT_MODULE(bsg_launch_sync_sync)
