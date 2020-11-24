// STD 10-30-16
//
// Synchronous 1-port ram with byte masking
// Only one read or one write may be done per cycle.
//

module bsg_mem_1rw_sync_mask_write_byte #(parameter els_p = -1
                                         ,parameter data_width_p = -1
                                         ,parameter latch_last_read_p = 0
                                         ,parameter addr_width_lp = `BSG_SAFE_CLOG2(els_p)
                                         ,parameter write_mask_width_lp = data_width_p>>3
                                         ,parameter harden_p = 1
                                         )
  (input                           clk_i
  ,input                           reset_i
  ,input                           v_i
  ,input                           w_i
  ,input [addr_width_lp-1:0]       addr_i
  ,input [data_width_p-1:0]        data_i
  ,input [write_mask_width_lp-1:0] write_mask_i
  ,output [data_width_p-1:0]       data_o
  );

  
  logic [data_width_p-1:0] w_bmask_li;

  bsg_expand_bitmask
   #(.in_width_p(write_mask_width_lp)
    ,.expand_p(8)
    )
   bitmask
    (.i(write_mask_i)
    ,.o(w_bmask_li)
    );

  bsg_mem_1rw_sync_mask_write_bit
   #(.width_p(data_width_p)
    ,.els_p(els_p)
    ,.latch_last_read_p(latch_last_read_p)
    ,.harden_p(harden_p)
    )
   mem
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.v_i(v_i)
    ,.w_i(w_i)
    ,.addr_i(addr_i)
    ,.data_i(data_i)
    ,.w_mask_i(w_bmask_li)
    ,.data_o(data_o)
    );

  // synopsys translate_off
  always_comb
    assert (data_width_p % 8 == 0)
      else $error("data width should be a multiple of 8 for byte masking");

  initial
    begin
      $display("## bsg_mem_1rw_sync_mask_write_byte: instantiating data_width_p=%d, els_p=%d (%m)",data_width_p,els_p);
    end
  // synopsys translate_on
   
endmodule
