// MBT 7/24/2014
//
// bsg_sync_sync
//
// This is just two synchronization flops.
//
// DWP 4/10/2025
// moved rp groups to asic

`include "bsg_defines.sv"

module bsg_sync_sync #(parameter `BSG_INV_PARAM(width_p), harden_p=0)
   (
      input oclk_i
    , input  [width_p-1:0] iclk_data_i
    , output [width_p-1:0] oclk_data_o // after sync flops
    );

`ifndef BSG_HIDE_FROM_SYNTHESIS
   initial
     begin
        $display("%m: instantiating bss of size %d",width_p);
     end
`endif

  for (genvar i = 0; i < width_p; i++)
    begin : rof
      bsg_sync_sync_unit bss
       (.oclk_i(oclk_i)
        ,.iclk_data_i(iclk_data_i[i])
        ,.oclk_data_o(oclk_data_o[i])
        );
    end

endmodule

`BSG_ABSTRACT_MODULE(bsg_sync_sync)
