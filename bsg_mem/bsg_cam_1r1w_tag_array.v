/*
 * This module is made for use in bsg_cams, managing the valids and tags for each entry.
 * We separate v_rs and tags so that we can support reset with minimal hardware.
 * This module does not protect against setting multiple entries to the same value -- this must be
 * prevented at a higher protocol level, if desired
 */
`include "bsg_defines.v"

module bsg_cam_1r1w_tag_array
 #(parameter width_p  = "inv"
   , parameter els_p      = "inv"

   , parameter multiple_entries_p = 0
   )
  (input                          clk_i
   , input                        reset_i

   // zero or one-hot
   , input [els_p-1:0]            w_v_i
   // Mutually exclusive set or clear
   , input                        w_set_not_clear_i
   // Tag to set or clear
   , input [width_p-1:0]          w_tag_i
   // Vector of empty CAM entries
   , output logic [els_p-1:0]     w_empty_o
   
   // Async read
   , input                        r_v_i
   // Tag to match on read
   , input [width_p-1:0]          r_tag_i
   // one or zero-hot
   , output logic [els_p-1:0]     r_match_o
   );

  logic [els_p-1:0][width_p-1:0] tag_r;
  logic [els_p-1:0] v_r;
  
  for (genvar i = 0; i < els_p; i++)
    begin : tag_array
      bsg_dff_reset_en
       #(.width_p(1))
       v_reg
        (.clk_i(clk_i)
         ,.reset_i(reset_i)

         ,.en_i(w_v_i[i])
         ,.data_i(w_set_not_clear_i)

         ,.data_o(v_r[i])
         );

      bsg_dff_en
       #(.width_p(width_p))
       tag_r_reg
        (.clk_i(clk_i)

         ,.en_i(w_v_i[i] & w_set_not_clear_i)
         ,.data_i(w_tag_i)
         ,.data_o(tag_r[i])
         );

      assign r_match_o[i] = r_v_i & v_r[i] & (tag_r[i] == r_tag_i);
	  assign w_empty_o[i] = ~v_r[i];
    end

  //synopsys translate_off
  always_ff @(negedge clk_i) begin
    assert(multiple_entries_p || reset_i || $countones(r_match_o) <= 1)
      else $error("Multiple similar entries are found in match_array\
                   %x while multiple_entries_p parameter is %d\n", r_match_o,
                   multiple_entries_p);       
	
	assert(reset_i || $countones(w_v_i & {els_p{w_set_not_clear_i}}) <= 1)
      else $error("Inv_r one-hot write address %b\n", w_v_i);
  end 
  //synopsys translate_on

endmodule
