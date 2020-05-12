/*
 * This module is made for use in bsg_cams, managing the valids and tags for each entry.
 * We separate v_rs and tags so that we can support reset with minimal hardware.
 * This module does not protect against setting multiple entries to the same value -- this must be
 * prevented at a higher protocol level, if desired
 */
module bsg_cam_1r1w_tag_array
 #(parameter width_p  = "inv"
   , parameter els_p      = "inv"

   , parameter multiple_entries_p = 0
   )
  (input                          clk_i
   , input                        reset_i

   // Mutually exclusive set or clear
   , input                        w_v_i
   , input                        w_set_not_clear_i
   // Replacement way for a set
   , input [els_p-1:0]            w_repl_i
   // Tag to set or clear
   , input [width_p-1:0]          w_tag_i

   // Vector of empty CAM entries
   , output logic [els_p-1:0]     empty_o
   
   // Tag to match on read
   , input [width_p-1:0]          r_tag_i
   // one or zero-hot
   , output logic [els_p-1:0]     r_v_o
   );

  logic [els_p-1:0][width_p-1:0] tag_r;
  logic [els_p-1:0] v_r;
  
  for (genvar i = 0; i < els_p; i++)
    begin : tag_array
      wire r_tag_match = v_r[i] & (tag_r[i] == r_tag_i);
      wire w_tag_match = v_r[i] & (tag_r[i] == w_tag_i);

      bsg_dff_reset_set_clear
       #(.width_p(1))
       v_reg
        (.clk_i(clk_i)
         ,.reset_i(reset_i)
         ,.set_i(w_v_i & w_set_not_clear_i & w_repl_i[i])
         ,.clear_i(w_v_i & ~w_set_not_clear_i & w_tag_match)

         ,.data_o(v_r[i])
         );

      bsg_dff_en
       #(.width_p(width_p))
       tag_r_reg
        (.clk_i(clk_i)

         ,.en_i(w_v_i & w_set_not_clear_i & w_repl_i[i])
         ,.data_i(w_tag_i)
         ,.data_o(tag_r[i])
         );
      assign r_v_o[i]   =  r_tag_match;
	  assign empty_o[i] = ~v_r[i];
    end

  //synopsys translate_off
  always_ff @(negedge clk_i) begin
    assert(multiple_entries_p || reset_i || $countones(r_v_o) <= 1)
      else $error("Multiple similar entries are found in match_array\
                    %x while multiple_entries_p parameter is %d\n", r_v_o,
                    multiple_entries_p);       
	
	assert(reset_i || $countones(w_v_i) <= 1)
      else $error("Inv_r one-hot write address %b\n", w_v_i);
  end 
  //synopsys translate_on

endmodule
