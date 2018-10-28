/*
* 
* Content Addressable Memory (CAM) module
* The r_data_i is received as an input and is compared against all
* the valid enteries in the CAM. For each entery, if r_data_i is the same as
* the stored pattern in that entery, the corresponding bit in match_array is
* set. Based on the multiple_entries_p parameter, the match_array is
* sent to a one_hot_encoder or a priority_encoder to generate
* the address of the match location.
*
*/

module bsg_cam_1r1w
  #(parameter els_p=512
    ,parameter width_p= 32
    ,parameter multiple_entries_p=0
  )
  (input clk_i
   ,input reset_i
   ,input w_v_i
   ,input r_v_i
   ,input w_set_not_clear_i
   ,input [els_p-1:0] w_addr_i
   ,input [width_p-1:0] w_data_i
   ,input [width_p-1:0] r_data_i
   ,output logic r_v_o
   ,output logic [els_p-1:0] r_addr_o
  );

  logic [width_p-1:0] mem [0:els_p-1];
  logic [els_p-1:0] match_array;
  logic [els_p-1:0] valid;

  wire ohe_v, pe_v;
  wire [els_p-1-1:0] ohe_addr, pe_addr;
  logic [els_p-1:0] match_array_ohe, match_array_pe;

   
  //write the input pattern into the cam and set the corresponding
  //valid bit
  always_ff @(posedge clk_i) begin
    if (reset_i) begin: fi1
      valid <= 0;
    end else if (w_v_i && !reset_i) begin: fi2
      assert(w_addr_i < els_p)
        else $error("Invalid address %x of size %x\n", w_addr_i, els_p);

      //w_set_not_clear_i=1 sets the valid bit and
      //w_set_not_clear_i=0 makes the corresponding  entry invalid
      valid[w_addr_i] <= w_set_not_clear_i;
      mem[w_addr_i] <= w_data_i;
    end
  end

  //compare the input pattern with all stored valid patterns inside
  //the cam.In the case of a match, set the corresponding bit in
  //match_array
  genvar i;
  generate begin
    for (i = 0; i < els_p; i++) begin: rof1
      always_comb begin
        if (reset_i) begin: fi3
          match_array[i] = 1'b0;
        end else if ((mem[i] == r_data_i) && valid[i]) begin: fi4
          match_array[i] = 1'b1;
        end else
          match_array[i] = 1'b0;
      end
    end
  end
  endgenerate

  //If multiple_entries_p is 1, the match_array is sent to the
  //priority encoder to select the match_address.
  bsg_priority_encode
    #(.width_p (els_p)
      ,.lo_to_hi_p (1)
    ) pe
    (.i (match_array_pe)
     ,.addr_o (pe_addr)
     ,.v_o (pe_v)
    );

  //If multiple_entries_p is 0, the match_array is sent to the
  //one hot encoder to select the match_address.
  bsg_encode_one_hot
    #(.width_p (els_p)
      ,.lo_to_hi_p (1)
    ) ohe
    (.i (match_array_ohe)
     ,.addr_o (ohe_addr)
     ,.v_o (ohe_v)
    );

  //based on the multiple_entries_p oarameter, the output is selected
  //from either priority encoder or the one hot encoder.
  always_comb begin
    if (multiple_entries_p == 1'b0 && r_v_i == 1'b1) begin: fi5
      assert($countones(match_array) <= 1)
        else $error("Multiple similar entries are found in input %x\
  while multiple_entries_p parameter is %d\n", match_array,
  multiple_entries_p); 
      
      match_array_ohe = match_array;
      r_addr_o = ohe_addr;
      r_v_o = ohe_v;
    end else if (multiple_entries_p == 1'b1 && r_v_i == 1'b1) begin: fi6       
      match_array_pe = match_array;
      r_addr_o = pe_addr;
      r_v_o = pe_v;
    end
  end


endmodule
