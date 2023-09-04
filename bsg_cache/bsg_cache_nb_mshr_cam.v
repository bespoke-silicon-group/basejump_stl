/*
 * Non blocking cache MSHR CAM
 */

`include "bsg_defines.v"

module bsg_cache_nb_mshr_cam
 #(parameter `BSG_INV_PARAM(els_p)
   , parameter `BSG_INV_PARAM(tag_width_p)
   , parameter `BSG_INV_PARAM(data_width_p)
   , parameter mask_width_p = data_width_p<<3

   , parameter safe_els_lp = `BSG_MAX(els_p,1)
   )
  (input                             clk_i
   , input                           reset_i

   // Synchronous write/invalidate of a tag
   // one or zero-hot
   , input [safe_els_lp-1:0]         w_v_i
   , input                           w_set_not_clear_i
   // Tag/data to set on write
   , input [tag_width_p-1:0]         w_tag_i
   , input [data_width_p-1:0]        w_data_i
   , input [mask_width_p-1:0]        w_mask_i
   // Metadata useful for an external replacement policy
   // Whether there's an empty entry in the tag array
   , output [safe_els_lp-1:0]        w_empty_o
   
   // Asynchronous read of a tag, if exists
   , input                           r_v_i
   , input [tag_width_p-1:0]         r_tag_i
   , output logic [data_width_p-1:0] r_data_o
   , output logic [safe_els_lp-1:0]  r_tag_match_o
   , output logic                    r_v_o
  );

  logic [safe_els_lp-1:0] tag_r_match_lo;
  
  // The cache line addr storage
  bsg_cam_1r1w_tag_array #(
    .width_p(tag_width_p)
    ,.els_p(safe_els_lp)
  ) cam_tag_array (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.w_v_i(w_v_i)
    ,.w_set_not_clear_i(w_set_not_clear_i)
    ,.w_tag_i(w_tag_i)
    ,.w_empty_o(w_empty_o)

    ,.r_v_i(r_v_i)
    ,.r_tag_i(r_tag_i)
    ,.r_match_o(tag_r_match_lo)
    );

  // The Store Tag Miss & valid bits storage
  bsg_mem_1r1w_one_hot_mask_write_bit #(
    .width_p(1+mask_width_p)
    ,.els_p(safe_els_lp)
  ) one_hot_tag_mem (
    .w_clk_i(clk_i)
    ,.w_reset_i(reset_i)

    ,.w_v_i(w_v_i)
    ,.w_data_i(w_tag_i)
    ,.w_mask_i(w_mask_i)

    ,.r_v_i(tag_r_match_lo)
    ,.r_data_o()
    );
  
  // The data storage
  bsg_mem_1r1w_one_hot #(
    .width_p(data_width_p)
    ,.els_p(safe_els_lp)
  ) one_hot_mem (
    .w_clk_i(clk_i)
    ,.w_reset_i(reset_i)

    ,.w_v_i(w_v_i)
    ,.w_data_i(w_data_i)

    ,.r_v_i(tag_r_match_lo)
    ,.r_data_o(r_data_o)
    );

  assign r_tag_match_o = tag_r_match_lo;
  assign r_v_o = |tag_r_match_lo;

endmodule

`BSG_ABSTRACT_MODULE(bsg_cam_1r1w_unmanaged)