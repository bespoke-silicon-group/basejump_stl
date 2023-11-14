`include "bsg_defines.sv"
`include "bsg_cache.svh"

module bsg_cache_to_axi_ordering
  import bsg_axi_pkg::*;
  #(parameter `BSG_INV_PARAM(addr_width_p)
    ,parameter `BSG_INV_PARAM(block_size_in_words_p)
    ,parameter `BSG_INV_PARAM(data_width_p)
    ,parameter `BSG_INV_PARAM(mask_width_p)
    ,parameter `BSG_INV_PARAM(num_cache_p)
    ,parameter tag_fifo_els_p=num_cache_p

    ,parameter `BSG_INV_PARAM(axi_id_width_p)
    ,parameter `BSG_INV_PARAM(axi_data_width_p)
    ,parameter `BSG_INV_PARAM(axi_burst_len_p)
    ,parameter `BSG_INV_PARAM(axi_burst_type_p)

    ,parameter strb_width_lp=(data_width_p>>3)
    ,parameter byte_mask_width_lp=(block_size_in_words_p*strb_width_lp)
    ,parameter lg_byte_mask_width_lp=`BSG_SAFE_CLOG2(byte_mask_width_lp)
    ,parameter cam_tag_width_lp=(addr_width_p-lg_byte_mask_width_lp)
  )
  (
    input clk_i
    ,input reset_i

    ,input r_v_i
    ,input [addr_width_p-1:0] r_addr_i
    ,output logic r_fence_o

    ,input w_v_i
    ,input [addr_width_p-1:0] w_addr_i
    ,output logic w_fence_o

    ,input axi_awvalid_i
    ,input axi_awready_i
    ,input axi_bvalid_i
    ,input axi_bready_i

    ,input axi_arvalid_i
    ,input axi_arready_i
    ,input axi_rlast_i
    ,input axi_rvalid_i
    ,input axi_rready_i
  );

  logic wcam_set_v_li, wcam_clr_v_li;
  logic [tag_fifo_els_p-1:0] wcam_set_li, wcam_clr_li;
  logic [tag_fifo_els_p-1:0] wcam_w_v_li, wcam_w_empty_lo, wcam_r_match_lo;
  logic wcam_set_not_clear_li, wcam_r_v_li;
  logic [cam_tag_width_lp-1:0] wcam_w_tag_li, wcam_r_tag_li;

  logic rcam_set_v_li, rcam_clr_v_li;
  logic [tag_fifo_els_p-1:0] rcam_set_li, rcam_clr_li;
  logic [tag_fifo_els_p-1:0] rcam_w_v_li, rcam_w_empty_lo, rcam_r_match_lo;
  logic rcam_set_not_clear_li, rcam_r_v_li;
  logic [cam_tag_width_lp-1:0] rcam_w_tag_li, rcam_r_tag_li;

  // fence write or read requests if:
  // - there's a pending request in the opposite channel for the same addr
  // - the addr CAM is full
  // - the addr CAM is being cleared in this cycle
  assign r_fence_o = r_v_i & ((|wcam_r_match_lo) | (~|rcam_w_empty_lo) | rcam_clr_v_li);
  assign w_fence_o = w_v_i & ((|rcam_r_match_lo) | (~|wcam_w_empty_lo) | wcam_clr_v_li);

  // write channel
  assign wcam_set_v_li = axi_awvalid_i & axi_awready_i;
  //assign wcam_clr_v_li = axi_bvalid_i & axi_bready_i;

  assign wcam_w_v_li = wcam_clr_v_li ? wcam_clr_li : (wcam_set_v_li ? wcam_set_li : '0);
  assign wcam_set_not_clear_li = wcam_set_v_li;
  assign wcam_w_tag_li = (w_addr_i >> lg_byte_mask_width_lp);

  assign wcam_r_v_li = r_v_i;
  assign wcam_r_tag_li = (r_addr_i >> lg_byte_mask_width_lp);

  bsg_cam_1r1w_tag_array #(
    .width_p(cam_tag_width_lp)
    ,.els_p(tag_fifo_els_p)
  ) w_addr_cam (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.w_v_i(wcam_w_v_li)
    ,.w_set_not_clear_i(wcam_set_not_clear_li)
    ,.w_tag_i(wcam_w_tag_li)
    ,.w_empty_o(wcam_w_empty_lo)

    ,.r_v_i(wcam_r_v_li)
    ,.r_tag_i(wcam_r_tag_li)
    ,.r_match_o(wcam_r_match_lo)
  );

  bsg_dff_reset #(
    .width_p(1)
  ) w_reg (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.data_i(axi_bvalid_i & axi_bready_i)
    ,.data_o(wcam_clr_v_li)
  );

  if(tag_fifo_els_p == 1) begin
    assign wcam_set_li = 1'b1;
    assign wcam_clr_li = 1'b1;
  end
  else begin
    bsg_counter_clear_up_one_hot #(
      .max_val_p(tag_fifo_els_p-1)
    ) wcam_set_oh (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.clear_i(1'b0)
      ,.up_i(wcam_set_v_li)
      ,.count_r_o(wcam_set_li)
    );

    bsg_counter_clear_up_one_hot #(
      .max_val_p(tag_fifo_els_p-1)
    ) wcam_clr_oh (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.clear_i(1'b0)
      ,.up_i(wcam_clr_v_li)
      ,.count_r_o(wcam_clr_li)
    );
  end

  // read channel
  assign rcam_set_v_li = axi_arvalid_i & axi_arready_i;
  //assign rcam_clr_v_li = axi_rvalid_i & axi_rlast_i & axi_rready_i;

  assign rcam_w_v_li = rcam_clr_v_li ? rcam_clr_li : (rcam_set_v_li ? rcam_set_li : '0);
  assign rcam_set_not_clear_li = rcam_set_v_li;
  assign rcam_w_tag_li = (r_addr_i >> lg_byte_mask_width_lp);

  assign rcam_r_v_li = w_v_i;
  assign rcam_r_tag_li = (w_addr_i >> lg_byte_mask_width_lp);

  bsg_cam_1r1w_tag_array #(
    .width_p(cam_tag_width_lp)
    ,.els_p(tag_fifo_els_p)
  ) r_addr_cam (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.w_v_i(rcam_w_v_li)
    ,.w_set_not_clear_i(rcam_set_not_clear_li)
    ,.w_tag_i(rcam_w_tag_li)
    ,.w_empty_o(rcam_w_empty_lo)

    ,.r_v_i(rcam_r_v_li)
    ,.r_tag_i(rcam_r_tag_li)
    ,.r_match_o(rcam_r_match_lo)
  );

  bsg_dff_reset #(
    .width_p(1)
  ) r_reg (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.data_i(axi_rvalid_i & axi_rlast_i & axi_rready_i)
    ,.data_o(rcam_clr_v_li)
  );

  if(tag_fifo_els_p == 1) begin
    assign rcam_set_li = 1'b1;
    assign rcam_clr_li = 1'b1;
  end
  else begin
    bsg_counter_clear_up_one_hot #(
      .max_val_p(tag_fifo_els_p-1)
    ) rcam_set_oh (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.clear_i(1'b0)
      ,.up_i(rcam_set_v_li)
      ,.count_r_o(rcam_set_li)
    );

    bsg_counter_clear_up_one_hot #(
      .max_val_p(tag_fifo_els_p-1)
    ) rcam_clr_oh (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.clear_i(1'b0)
      ,.up_i(rcam_clr_v_li)
      ,.count_r_o(rcam_clr_li)
    );
  end

endmodule

`BSG_ABSTRACT_MODULE(bsg_cache_to_axi_ordering)
