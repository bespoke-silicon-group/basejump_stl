`include "bsg_defines.v"

module bsg_mem_1r1w_sync_mask_write_var #
  (parameter width_p=-1
  ,parameter mask_width_p=-1
  ,parameter els_p=-1
  ,parameter chunk_size_lp = width_p / mask_width_p
  ,parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
  ,parameter read_write_same_addr_p=0
  ,parameter harden_p=0)
  (input                      clk_i
  ,input                      reset_i
  // write
  ,input                      w_v_i
  ,input        [width_p-1:0] w_mask_i
  ,input  [addr_width_lp-1:0] w_addr_i
  ,input        [width_p-1:0] w_data_i
  // read
  ,input                      r_v_i
  ,input  [addr_width_lp-1:0] r_addr_i
  ,output       [width_p-1:0] r_data_o);

  always_ff @(posedge clk_i)
    assert((width_p % mask_width_p) == 0)
      else $error("%m: partial masking is not supported");

  genvar i;

  for (i = 0; i < chunk_size_lp; i++) begin

    bsg_mem_1r1w_sync #
      (.width_p(mask_width_p)
      ,.els_p(els_p)
      ,.read_write_same_addr_p(read_write_same_addr_p)
      ,.harden_p(harden_p))
    mem
      (.clk_i(clk_i)
      ,.reset_i(reset_i)
      // write
      ,.w_v_i(w_v_i & w_mask_i[i*mask_width_p])
      ,.w_addr_i(w_addr_i)
      ,.w_data_i(w_data_i[(i+1)*mask_width_p-1:i*mask_width_p])
      // read
      ,.r_v_i(r_v_i)
      ,.r_addr_i(r_addr_i)
      ,.r_data_o(r_data_o[(i+1)*mask_width_p-1:i*mask_width_p]));

  end

endmodule
