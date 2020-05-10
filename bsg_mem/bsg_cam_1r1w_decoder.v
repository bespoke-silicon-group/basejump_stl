/*
 * This module is made for use in bsg_cam_1r1w_sync, managing the valids and tags for each entry.
 * We separate valids and tags so that we can support reset with minimal hardware.
 * This module does not protect against setting multiple entries to the same value -- this must be
 * prevented at a higher protocol level, if desired
 */
module bsg_cam_1r1w_decoder
 #(parameter tag_width_p  = "inv"
   , parameter els_p      = "inv"

   , parameter multiple_entries_p = 0
   )
  (input                          clk_i
   , input                        reset_i

   // Sync write or clear
   , input                        w_v_i
   , input                        w_set_not_clear_i
   , input [tag_width_p-1:0]      w_tag_i
   , input [els_p-1:0]            w_addr_i
   // Vector of empty CAM entries
   , output logic [els_p-1:0]     empty_o
   
   , input                        r_v_i
   , input [tag_width_p-1:0]      r_tag_i
   , output logic [els_p-1:0]     r_addr_o
   );

  logic [els_p-1:0][tag_width_p-1:0] tag_mem;
  logic [els_p-1:0] valid;
  
  always_ff @(posedge clk_i)
    if (reset_i)
      valid <= '0;
    else
      for (integer i = 0; i < els_p; i++)
        if (w_v_i & w_addr_i[i])
          begin
            valid[i]   <= w_set_not_clear_i;
            tag_mem[i] <= w_tag_i;
          end

  for (genvar i = 0; i < els_p; i++) begin: rof
    assign r_addr_o[i] = r_v_i & (tag_mem[i] == r_tag_i) & valid[i];
	assign empty_o[i] = ~valid[i];
  end
  
  //synopsys translate_off
  always_ff @(negedge clk_i) begin
    assert(multiple_entries_p || reset_i || $countones(r_addr_o) <= 1)
      else $error("Multiple similar entries are found in match_array\
                    %x while multiple_entries_p parameter is %d\n", r_addr_o,
                    multiple_entries_p);       
	
	assert(reset_i || ~w_v_i || $countones(w_addr_i) <= 1)
      else $error("Invalid one-hot write address %b\n", w_addr_i);
  end 
  //synopsys translate_on

endmodule
