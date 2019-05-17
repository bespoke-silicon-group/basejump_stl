// NOTE: Users of BaseJump STL should not instantiate this module directly
// they should use bsg_mem_1r1w_sync_mask_write_byte.

module bsg_mem_1rw_sync_mask_write_byte_synth 
  #(parameter els_p="inv"
		, parameter data_width_p="inv"
    
    , parameter latch_last_read_p=0

		, localparam addr_width_lp = `BSG_SAFE_CLOG2(els_p)
		, localparam write_mask_width_lp = data_width_p>>3
  )
  (
    input clk_i
    , input reset_i

    , input v_i
    , input w_i

    , input [addr_width_lp-1:0] addr_i
    , input [data_width_p-1:0] data_i

    // for each bit set in the mask, a byte is written
    , input [write_mask_width_lp-1:0] write_mask_i

    , output [data_width_p-1:0] data_o
  );

  genvar i;

  for (i = 0; i < write_mask_width_lp; i=i+1) begin: bk
    bsg_mem_1rw_sync #(
      .width_p(8)
      ,.els_p(els_p)
      ,.latch_last_read_p(latch_last_read_p)
    ) mem_1rw_sync (
      .clk_i  (clk_i)
      ,.reset_i(reset_i)
      ,.data_i (data_i[(i*8)+:8])
      ,.addr_i (addr_i)
      ,.v_i    (v_i)
      ,.w_i    (w_i & write_mask_i[i])
      ,.data_o (data_o[(i*8)+:8])
    );
  end

endmodule
