/*
* 
* Content Addressable Memory (CAM) module
* The r_data_i is received as an input and is compared against all
* the valid entries in the CAM. For each entery, if r_data_i is the same as
* the stored pattern in that entery, the corresponding bit in match_array is
* set. Based on the multiple_entries_p parameter, which indicates
* whether multiple entries with the same key are allowed, the match_array is
* sent to either a one_hot_encoder or a priority_encoder to generate
* the address of the match location. Also by setting the find_empty_entry_p
* parameter, if there is an empty entry in the memory, empty_v_o is raised and
* the first empty entry's address is put on empty_addr_o. This can help other
* modules interacting with CAM, to easily find an address to write to.
*
*/

module bsg_cam_1r1w
  #(parameter els_p               = "inv"
    ,parameter width_p            = "inv"
    ,parameter multiple_entries_p = "inv"
	,parameter find_empty_entry_p = "inv"
	
	,localparam lg_els_lp         = `BSG_SAFE_CLOG2(els_p)
  )
  (input                          clk_i
   , input                        reset_i
   , input                        en_i

   , input                        w_v_i
   , input                        w_set_not_clear_i
   , input [lg_els_lp-1:0]        w_addr_i
   , input [width_p-1:0]          w_data_i
   
   , input                        r_v_i
   , input [width_p-1:0]          r_data_i
   
   , output logic                 r_v_o
   , output logic [lg_els_lp-1:0] r_addr_o
   
   , output logic                 empty_v_o
   , output logic [lg_els_lp-1:0] empty_addr_o
  );

  
  logic [width_p-1:0] mem [0:els_p-1];
  logic [els_p-1:0]   match_array, empty_array;
  logic [els_p-1:0]   valid;
  logic               matched, empty_found;
  
  assign r_v_o     = en_i & r_v_i & matched;
  assign empty_v_o = en_i & empty_found;
   
  //write the input pattern into the cam and set the corresponding valid bit
  always_ff @(posedge clk_i) begin
    if (reset_i) begin: fi
      valid <= '0;
    end 
    else if (en_i && w_v_i) begin: fi2
      //w_set_not_clear_i=1 sets the valid bit and
      //w_set_not_clear_i=0 makes the corresponding entry invalid
      valid[w_addr_i] <= w_set_not_clear_i;
      mem[w_addr_i]   <= w_data_i;
    end
  end
  
   
  //compare the input pattern with all stored valid patterns inside
  //the cam.In the case of a match, set the corresponding bit in
  //match_array
  genvar i;
  for (i = 0; i < els_p; i++) begin: rof
    assign  match_array[i] = ~reset_i & en_i & (mem[i] == r_data_i) & valid[i];
	assign  empty_array[i] = ~reset_i & en_i & ~valid[i];
  end
  
   
  generate begin: gen
    if(multiple_entries_p) begin: fi3
      //If multiple_entries_p is 1, the match_array is sent to the
      //priority encoder to select the match_address
      bsg_priority_encode
        #(.width_p (els_p)
          ,.lo_to_hi_p (1)
        ) pe
        (.i (match_array)
         ,.addr_o (r_addr_o)
         ,.v_o (matched)
        );
    end
    else begin: fi4
      //If multiple_entries_p is 0, the match_array is sent to the
      //one hot encoder to select the match_address
      bsg_encode_one_hot
        #(.width_p (els_p)
          ,.lo_to_hi_p (1)
        ) ohe
        (.i (match_array)
         ,.addr_o (r_addr_o)
         ,.v_o (matched)
        );
    end 
  end
  endgenerate
  
  generate begin: gen2
    if(find_empty_entry_p) begin: fi5
	// If find_empty_entry_p is 1, finds the first empty entry in the cam,
    // and puts it on empty_addr_o and raises the empty_v_o
      bsg_priority_encode
        #(.width_p(els_p)
          ,.lo_to_hi_p(1)
        ) epe
        (.i(empty_array)
         ,.addr_o(empty_addr_o)
         ,.v_o(empty_found)
        );
    end
	else begin: fi6
	// Otherwise, sets empty_v_o and empty_addr_o to zero
	  assign empty_v_o    = 1'b0;
	  assign empty_addr_o = '0;
	end
  end
  endgenerate
  
  
  always_ff @(negedge clk_i) begin
    if (~multiple_entries_p & ~reset_i & en_i & r_v_i) begin: fi_debug1
      assert($countones(match_array) <= 1)
        else $error("Multiple similar entries are found in match_array\
                    %x while multiple_entries_p parameter is %d\n", match_array,
                    multiple_entries_p);       
    end
	
	if(~reset_i & en_i & w_v_i) begin: fi_debug2
	  assert(w_addr_i < els_p)
        else $error("Invalid address %x of size %x\n", w_addr_i, els_p);
	end
  end 

endmodule
