// lock when lock and req
// unlock when ~lock and req

module bsg_locking_arb_fixed_new #( parameter inputs_p="inv"
                                 , parameter lo_to_hi_p=0
                                 )
  ( input   clk_i
  , input   reset_i
  , input   ready_i

  , input        [inputs_p-1:0] locks_i

  , input        [inputs_p-1:0] reqs_i
  , output logic [inputs_p-1:0] grants_o

  , output logic lock_o
  );  

  wire [inputs_p-1:0] not_req_mask_r, req_mask_r;
  wire lock_onlocked_lo, lock_selected_lo, unlock;  
  wire is_locked = |not_req_mask_r;

  bsg_mux_one_hot #(.width_p(1) ,.els_p(inputs_p) )
   lock_onlocked_mux
   (.data_i(locks_i)
    ,.sel_one_hot_i(req_mask_r)
    ,.data_o(lock_onlocked_lo)
    );
  // unlock when the lock input on the locked channel is low
  assign unlock = is_locked & ~lock_onlocked_lo;

  bsg_dff_reset_en #( .width_p(inputs_p) )
    req_words_reg
      ( .clk_i  ( clk_i )
      , .reset_i( reset_i | unlock ) 
      , .en_i   ( (&req_mask_r) & (|grants_o) ) // update the lock when it is not locked & a req is granted
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
      
  bsg_mux_one_hot #(.width_p(1) ,.els_p(inputs_p) )
   lock_output_mux
   (.data_i(locks_i)
    ,.sel_one_hot_i(grants_o)
    ,.data_o(lock_selected_lo)
    );
  // lock_o signal keeps high as long as the arbiter is on lock
  assign lock_o = (|grants_o) ? lock_selected_lo : is_locked;

endmodule

