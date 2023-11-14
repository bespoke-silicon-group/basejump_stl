`include "bsg_defines.sv"

module bsg_locking_arb_fixed #( parameter `BSG_INV_PARAM(inputs_p)
                             , parameter lo_to_hi_p=0
                             )
  ( input   clk_i
  , input   ready_then_i

   // to have continuous throughput, you will need to unlock on the same cycle
   // as the last word of a packet going through
  , input   unlock_i

  , input        [inputs_p-1:0] reqs_i
  , output logic [inputs_p-1:0] grants_o
  );  

  wire [inputs_p-1:0] not_req_mask_r, req_mask_r;

  bsg_dff_reset_en #( .width_p(inputs_p) )
    req_words_reg
      ( .clk_i  ( clk_i )
      , .reset_i( unlock_i )
       // lock in a request mask, if the current request mask is "everybody"
       // and somebody was granted their request.
      , .en_i   ( (&req_mask_r) & (|grants_o) )
      , .data_i ( ~grants_o )
      , .data_o ( not_req_mask_r )
      );

  assign req_mask_r = ~not_req_mask_r;

  bsg_arb_fixed #( .inputs_p(inputs_p), .lo_to_hi_p(lo_to_hi_p) )
    fixed_arb
      ( .ready_then_i ( ready_then_i )
      , .reqs_i  ( reqs_i & req_mask_r )
      , .grants_o( grants_o )
      );  

endmodule

`BSG_ABSTRACT_MODULE(bsg_locking_arb_fixed)

