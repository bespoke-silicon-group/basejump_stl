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

   // Synchronous read / valid
   , output logic [data_width_p-1:0] r_data_o
   , output logic                    r_v_o
  );

  logic [tag_width_p-1:0] r_tag_r;
  logic r_v_r;
  bsg_dff
   #(.width_p(tag_width_p))
   r_tag_reg
    (.clk_i(clk_i)

     ,.data_i(r_tag_i)
     ,.data_o(r_tag_r)
     );

  bsg_cam_1r1w
   #(.els_p(els_p)
     ,.tag_width_p(tag_width_p)
     ,.data_width_p(data_width_p)
     )
   cam
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.w_v_i(w_v_i)
     ,.w_set_not_clear_i(w_set_not_clear_i)
     ,.w_tag_i(w_tag_i)
     ,.w_data_i(w_data_i)
     ,.empty_o(empty_o)

     ,.r_tag_i(r_tag_r)
     ,.r_data_o(r_data_o)
     ,.r_v_o(r_v_o)
     );

endmodule

