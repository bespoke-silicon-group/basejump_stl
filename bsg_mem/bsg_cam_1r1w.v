/*
 * Asynchronous read 1r1w content addressable memory module.
 * Each entry has a tag and a data associated with it, and can be
 *   independently cleared and set
 * - Read searches the array for any data with r_tag_i
 * - Write allocates a new entry, replacing an existing entry with replacement
 *     scheme repl_scheme_p
 * - Write with w_nuke_i flag invalidates the cam
 * - Allocation happens in parallel with read, so it is possible in an LRU
 *     scheme for the currently-being-read item to be overwritten
 * - There are no concerns about simultaneous reading and writing
 * - It is generally discouraged to have multiple identical tags in the array,
 *     i.e. you should read the array to see if anything is there before
 *     writing; but if there are, then the data returned on read is the OR
 *     of the data. If you find that functionality useful, let us know =)
 */

`include "bsg_defines.sv"

module bsg_cam_1r1w
 #(parameter `BSG_INV_PARAM(els_p)
   , parameter `BSG_INV_PARAM(tag_width_p)
   , parameter `BSG_INV_PARAM(data_width_p)

   // The replacement scheme for the CAM
   , parameter repl_scheme_p = "lru"
   )
  (input                             clk_i
   , input                           reset_i

   // Synchronous write/invalidate of a tag
   , input                           w_v_i
   // When w_v_i & w_nuke_i, the whole cam array is invalidated
   , input                           w_nuke_i
   // Tag/data to set on write
   , input [tag_width_p-1:0]         w_tag_i
   , input [data_width_p-1:0]        w_data_i
   
   // Asynchronous read of a tag, if exists
   , input                           r_v_i
   , input [tag_width_p-1:0]         r_tag_i
   , output logic [data_width_p-1:0] r_data_o
   , output logic                    r_v_o
  );

  localparam safe_els_lp = `BSG_MAX(els_p,1);

  // The tag storage for the CAM
  logic [safe_els_lp-1:0] tag_r_match_lo;
  logic [safe_els_lp-1:0] tag_empty_lo;
  logic [safe_els_lp-1:0] repl_way_lo;
  wire [safe_els_lp-1:0] tag_w_v_li = repl_way_lo | {safe_els_lp{w_nuke_i}};
  bsg_cam_1r1w_tag_array
   #(.width_p(tag_width_p)
     ,.els_p(safe_els_lp)
     )
   cam_tag_array
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.w_v_i(tag_w_v_li)
     ,.w_set_not_clear_i(w_v_i & ~w_nuke_i)
     ,.w_tag_i(w_tag_i)
     ,.w_empty_o(tag_empty_lo)

     ,.r_v_i(r_v_i)
     ,.r_tag_i(r_tag_i)
     ,.r_match_o(tag_r_match_lo)
     );

  // The replacement scheme for the CAM
  bsg_cam_1r1w_replacement
   #(.els_p(safe_els_lp)
     ,.scheme_p(repl_scheme_p)
     )
   replacement
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.read_v_i(tag_r_match_lo)

     ,.alloc_v_i(w_v_i)
     ,.alloc_empty_i(tag_empty_lo)
     ,.alloc_v_o(repl_way_lo)
     );

  // The data storage for the CAM
  wire [safe_els_lp-1:0] mem_w_v_li = repl_way_lo;
  bsg_mem_1r1w_one_hot
   #(.width_p(data_width_p)
     ,.els_p(safe_els_lp)
     )
   one_hot_mem
    (.w_clk_i(clk_i)
     ,.w_reset_i(reset_i)

     ,.w_v_i(mem_w_v_li)
     ,.w_data_i(w_data_i)

     ,.r_v_i(tag_r_match_lo)
     ,.r_data_o(r_data_o)
     );

  assign r_v_o = |tag_r_match_lo;

endmodule

`BSG_ABSTRACT_MODULE(bsg_cam_1r1w)

