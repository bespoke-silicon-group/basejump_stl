`include "bsg_defines.v"

module bsg_mem_1rw_sync_mask_write_var #
  (parameter width_p=-1
  ,parameter mask_width_p=-1
  ,parameter els_p=-1
  ,parameter chunk_size_lp = width_p / mask_width_p
  ,parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p))
  (input                      clk_i
  ,input                      reset_i
  ,input        [width_p-1:0] data_i
  ,input        [width_p-1:0] w_mask_i
  ,input  [addr_width_lp-1:0] addr_i
  ,input                      v_i
  ,input                      w_i
  ,output       [width_p-1:0] data_o);

  always_ff @(posedge clk_i)
    assert((width_p % mask_width_p) == 0)
      else $error("%m: partial masking is not supported");

  genvar i;

  for (i = 0; i < chunk_size_lp; i++) begin

    bsg_mem_1rw_sync #
      (.width_p(mask_width_p)
      ,.els_p(els_p))
    mem
      (.clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.data_i(data_i[(i+1)*mask_width_p-1:i*mask_width_p])
      ,.addr_i(addr_i)
      ,.v_i(v_i)
      ,.w_i(w_i & w_mask_i[i*mask_width_p])
      ,.data_o(data_o[(i+1)*mask_width_p-1:i*mask_width_p]));

  end

endmodule
