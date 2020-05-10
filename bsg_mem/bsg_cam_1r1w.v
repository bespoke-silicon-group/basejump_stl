/*
 * Asynchronous read 1r1w content addressable memory module.
 * Each entry has a tag and a data associated with it, and can be independently cleared and set
 * Clients can use the (not one-hot) empty_o vector to determine their own replacement policy
 */

module bsg_cam_1r1w
 #(parameter els_p                = "inv"
   , parameter tag_width_p        = "inv"
   , parameter data_width_p       = "inv"
   )
  (input                             clk_i
   , input                           reset_i

   // one or zero-hot
   , input [els_p-1:0]               w_v_i
   // Whether to set entry or clear entry
   , input                           w_set_not_clear_i
   // Tag/data to set on write
   , input [tag_width_p-1:0]         w_tag_i
   , input [data_width_p-1:0]        w_data_i
   // Vector of empty CAM entries
   , output logic [els_p-1:0]        empty_o
   
   // Tag to match on read
   , input [tag_width_p-1:0]         r_tag_i
   // Asynchronous read / valid
   , output logic [data_width_p-1:0] r_data_o
   , output logic                    r_v_o
  );

  logic [els_p-1:0] cam_r_v_lo;
  bsg_cam_1r1w_tag_array
   #(.width_p(tag_width_p)
     ,.els_p(els_p)
     )
   cam_decoder
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.w_v_i(w_v_i)
     ,.w_set_not_clear_i(w_set_not_clear_i)
     ,.w_tag_i(w_tag_i)
     ,.empty_o(empty_o)

     ,.r_tag_i(r_tag_i)

     ,.r_v_o(cam_r_v_lo)
     );

  bsg_mem_1r1w_one_hot
   #(.width_p(data_width_p)
     ,.els_p(els_p)
     )
   one_hot_mem
    (.w_clk_i(clk_i)
     ,.w_reset_i(reset_i)

     ,.w_v_i(w_v_i)
     ,.w_data_i(w_data_i)

     ,.r_v_i(cam_r_v_lo)
     ,.r_data_o(r_data_o)
     );

  assign r_v_o = |cam_r_v_lo;

endmodule

