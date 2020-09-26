/**
 *  bsg_nonsynth_mem_1rw_sync_mask_write_byte_assoc.v
 *
 *  bsg_mem_1rw_sync_mask_write_byte implementation using associative array.
 *
 *  This is for simulating arbitrarily large memories.
 *
 */


`include "bsg_defines.v"

module bsg_nonsynth_mem_1rw_sync_mask_write_byte_assoc
  #(parameter data_width_p="inv"
    , parameter addr_width_p="inv"
    , parameter write_mask_width_lp=(data_width_p>>3)
  )
  (
    input clk_i
    , input reset_i

    , input v_i
    , input w_i

    , input [addr_width_p-1:0] addr_i
    , input [data_width_p-1:0] data_i
    , input [write_mask_width_lp-1:0] write_mask_i

    , output [data_width_p-1:0] data_o
  );

  for (genvar i = 0; i < write_mask_width_lp; i++) begin: bk
    bsg_nonsynth_mem_1rw_sync_assoc #(
      .addr_width_p(addr_width_p)      
      ,.width_p(8)
    ) mem_1rw_sync (
      .clk_i(clk_i)
      ,.reset_i(reset_i)

      ,.data_i(data_i[(i*8)+:8])
      ,.addr_i(addr_i)
      ,.v_i(v_i)
      ,.w_i(w_i & write_mask_i[i])
      ,.data_o(data_o[(i*8)+:8])
    );
  end
  


endmodule
