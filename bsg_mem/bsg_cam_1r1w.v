/*
 * Asynchronous read 1r1w content addressable memory module.
 * Each entry has a tag and a data associated with it, and can be independently cleared and set
 */

module bsg_cam_1r1w
 #(parameter els_p                = "inv"
   , parameter tag_width_p        = "inv"
   , parameter data_width_p       = "inv"

   // The replacement scheme for the CAM
   , parameter repl_scheme_p = "lru"
   )
  (input                             clk_i
   , input                           reset_i

   // Synchronous write/invalidate of a tag
   , input                           w_v_i
   , input                           w_set_not_clear_i
   // Tag/data to set on write
   , input [tag_width_p-1:0]         w_tag_i
   , input [data_width_p-1:0]        w_data_i
   
   // Asynchronous read of a tag, if exists
   , input                           r_v_i
   , input [tag_width_p-1:0]         r_tag_i
   , output logic [data_width_p-1:0] r_data_o
   , output logic                    r_v_o
  );

  // The tag storage for the CAM
  logic [els_p-1:0] tag_r_match_lo, tag_w_match_lo;
  logic [els_p-1:0] tag_empty_lo;
  logic [els_p-1:0] tag_w_v_li;
  bsg_cam_1r1w_tag_array
   #(.width_p(tag_width_p)
     ,.els_p(els_p)
     )
   cam_tag_array
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.w_v_i(tag_w_v_li)
     ,.w_set_not_clear_i(w_set_not_clear_i)
     ,.w_tag_i(w_tag_i)
     ,.w_match_o(tag_w_match_lo)
     ,.w_empty_o(tag_empty_lo)

     ,.r_tag_i(r_tag_i)
     ,.r_match_o(tag_r_match_lo)
     );

  // The replacement scheme for the CAM
  logic [els_p-1:0] repl_way_lo;
  logic [els_p-1:0] clear_way_lo;
  bsg_cam_1r1w_replacement
   #(.els_p(els_p)
     ,.scheme_p(repl_scheme_p)
     )
   replacement
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.r_v_i(r_v_o)
     ,.r_way_one_hot_i(tag_r_match_lo)

     ,.w_v_i(w_v_i)
     ,.w_way_one_hot_i(tag_w_match_lo)

     ,.empty_i(tag_empty_lo)
     ,.way_one_hot_o(repl_way_lo)
     );

  // The data storage for the CAM
  logic [els_p-1:0] mem_w_v_li;
  bsg_mem_1r1w_one_hot
   #(.width_p(data_width_p)
     ,.els_p(els_p)
     )
   one_hot_mem
    (.w_clk_i(clk_i)
     ,.w_reset_i(reset_i)

     ,.w_v_i(mem_w_v_li)
     ,.w_data_i(w_data_i)

     ,.r_v_i(tag_r_match_lo)
     ,.r_data_o(r_data_o)
     );

  assign clear_way_lo = tag_w_match_lo & {els_p{w_v_i & ~w_set_not_clear_i}};
  assign mem_w_v_li   = repl_way_lo & {els_p{w_v_i & w_set_not_clear_i}};
  assign tag_w_v_li   = w_set_not_clear_i ? mem_w_v_li : clear_way_lo;

  assign r_v_o = r_v_i & |tag_r_match_lo;

endmodule

