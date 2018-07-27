/**
 *  bsg_replacement.v
 */

module bsg_replacement(
  input clk_i
  ,input rst_i
  
  ,input [8:0] line_v_i // line and set in question

  ,input [8:0] line_tl_i  // write-onto-read
  ,input miss_minus_recover_v_i
  ,input tagged_access_v_i

  ,input ld_st_set_v_i  // used for load or store
  ,input wipe_set_v_i   // for flush or invalidate

  ,input ld_op_v_i
  ,input st_op_v_i
  ,input wipe_v_i       // for flush or invalidate
  
  ,input status_mem_re_i

  // outputs
  ,output logic dirty0_o
  ,output logic dirty1_o
  ,output logic mru_o
  ,output logic write_over_read_v_o  
);

  logic replacement_we;
  logic [2:0] replacement_data_in;
  logic [2:0] replacement_mask;
  
  logic [8:0] line_final;
  logic read_dirty_r; 

  assign replacement_data_in = wipe_v_i
    ? {2'b00, ~wipe_set_v_i}
    : {2'b11, ld_st_set_v_i};

  assign replacement_we = wipe_v_i | st_op_v_i | ld_op_v_i;

  assign line_final = (replacement_we | miss_minus_recover_v_i)
    ? line_v_i
    : line_tl_i;
  
  always_ff @ (posedge clk_i) begin
    read_dirty_r <= ~(replacement_we | miss_minus_recover_v_i);
  end

  assign write_over_read_v_o = st_op_v_i & tagged_access_v_i
    & (~read_dirty_r | ((~ld_st_set_v_i & ~dirty0_o) | (ld_st_set_v_i & ~dirty1_o)));

  assign replacement_mask = {
    (wipe_v_i ? ~wipe_set_v_i : (st_op_v_i ? ~ld_st_set_v_i : 1'b0)),
    (wipe_v_i ? wipe_set_v_i : (st_op_v_i ? ld_st_set_v_i : 1'b0)),
    (wipe_v_i | st_op_v_i | ld_op_v_i)
  };

  bsg_mem_1rw_sync_mask_write_bit #(.width_p(3), .els_p(512)) status_mem (
    .clk_i(clk_i)
    ,.reset_i(rst_i)
    ,.v_i(~rst_i & status_mem_re_i & replacement_we)
    ,.w_i(replacement_we & ~rst_i)
    ,.w_mask_i(replacement_mask)
    ,.addr_i(line_final)
    ,.data_i(replacement_data_in)
    ,.data_o({dirty0_o, dirty1_o, mru_o})
  );

endmodule
