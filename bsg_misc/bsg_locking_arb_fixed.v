`include "bsg_defines.v"

module bsg_locking_arb_fixed #( parameter inputs_p="inv"
                             , parameter lo_to_hi_p=0
                             )
  ( input   clk_i
  , input   ready_i

  , input   unlock_i

  , input        [inputs_p-1:0] reqs_i
  , output logic [inputs_p-1:0] grants_o
  );  

  wire [inputs_p-1:0] not_req_mask_r, req_mask_r;

  bsg_dff_reset_en #( .width_p(inputs_p) )
    req_words_reg
      ( .clk_i  ( clk_i )
      , .reset_i( unlock_i )
      , .en_i   ( (&req_mask_r) & (|grants_o) )
      , .data_i ( ~grants_o )
      , .data_o ( not_req_mask_r )
      );

  assign req_mask_r = ~not_req_mask_r;

  bsg_arb_fixed #( .inputs_p(inputs_p), .lo_to_hi_p(lo_to_hi_p) )
    fixed_arb
      ( .ready_i ( ready_i )
      , .reqs_i  ( reqs_i & req_mask_r )
      , .grants_o( grants_o )
      );  

endmodule

