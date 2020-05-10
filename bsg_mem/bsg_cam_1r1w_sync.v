/*
 * Synchnronous read 1r1w content addressable memory module.
 * Each entry has a tag and a data associated with it, and can be independently cleared and set
 * Clients can use the (not one-hot) empty_o vector to determine their own replacement policy
 */

module bsg_cam_1r1w_sync
 #(parameter els_p                = "inv"
   , parameter tag_width_p        = "inv"
   , parameter data_width_p       = "inv"
   )
  (input                             clk_i
   , input                           reset_i

   , input                           w_v_i
   , input                           w_set_not_clear_i
   , input [tag_width_p-1:0]         w_tag_i
   , input [els_p-1:0]               w_addr_i
   , input [data_width_p-1:0]        w_data_i
   , output logic [els_p-1:0]        empty_o
   
   , input                           r_v_i
   , input [tag_width_p-1:0]         r_tag_i

   , output logic [data_width_p-1:0] r_data_o
   , output logic                    r_v_o
  );

  logic [tag_width_p-1:0] r_tag_r;
  logic r_v_r;
  bsg_dff
   #(.width_p(1+tag_width_p))
   r_tag_reg
    (.clk_i(clk_i)

     ,.data_i({r_v_i, r_tag_i})
     ,.data_o({r_v_r, r_tag_r})
     );

  logic [els_p-1:0] cam_r_addr_lo;
  bsg_cam_1r1w_decoder
   #(.tag_width_p(tag_width_p)
     ,.els_p(els_p)
     )
   cam_decoder
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.w_v_i(w_v_i)
     ,.w_set_not_clear_i(w_set_not_clear_i)
     ,.w_tag_i(w_tag_i)
     ,.w_addr_i(w_addr_i)
     ,.empty_o(empty_o)

     ,.r_v_i(r_v_r)
     ,.r_tag_i(r_tag_r)

     ,.r_addr_o(cam_r_addr_lo)
     );

  bsg_mem_1r1w_one_hot
   #(.width_p(data_width_p)
     ,.els_p(els_p)
     )
   one_hot_mem
    (.w_clk_i(clk_i)
     ,.w_reset_i(reset_i)

     ,.w_v_i(w_v_i)
     ,.w_addr_i(w_addr_i)
     ,.w_data_i(w_data_i)

     ,.r_v_i(r_v_r)
     ,.r_addr_i(cam_r_addr_lo)
     ,.r_data_o(r_data_o)
     );

  assign r_v_o = |cam_r_addr_lo;

endmodule

