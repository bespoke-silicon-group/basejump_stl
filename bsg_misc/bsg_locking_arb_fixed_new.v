// unlock_type_p = implicit / explicit
// 0 implicit: lock when lock and req is granted. unlock when ~lock
// 1 explicit: automatically locks on grant and has a single lock signal high

module bsg_locking_arb_fixed_new #( parameter inputs_p="inv"
                                 , parameter unlock_type_p = 0
                                 , parameter lo_to_hi_p=0
                                 , parameter num_locks_p = (unlock_type_p == 0) ? inputs_p : 1
                                 )
  ( input   clk_i
  , input   reset_i
  , input   ready_i

  , input        [num_locks_p-1:0] switch_lock_i

  , input        [inputs_p-1:0] reqs_i
  , output logic [inputs_p-1:0] grants_o

  , output logic lock_o
  );  

  wire [inputs_p-1:0] not_req_mask_r, req_mask_r;
  wire unlock;  
  
  if (unlock_type_p == 0) // Implicit operating mode
    begin
      wire is_locked = |not_req_mask_r;
      wire lock_onlocked_lo, lock_selected_lo;
      bsg_mux_one_hot #(.width_p(1) ,.els_p(inputs_p) )
      lock_onlocked_mux
      (.data_i(switch_lock_i)
        ,.sel_one_hot_i(req_mask_r)
        ,.data_o(lock_onlocked_lo)
        );
      // unlock when the lock input on the locked channel is low
      assign unlock = is_locked & ~lock_onlocked_lo;

      bsg_mux_one_hot #(.width_p(1) ,.els_p(inputs_p) )
      lock_output_mux
        (.data_i(switch_lock_i)
        ,.sel_one_hot_i(grants_o)
        ,.data_o(lock_selected_lo)
        );
      // The lock_i can be passed to lock_o at the same cycle
      assign lock_o = (is_locked) ? lock_onlocked_lo : lock_selected_lo;
    end
  else  // Explicit operating mode
    begin
      assign unlock = switch_lock_i;
      assign lock_o = 1'b0;
    end

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
      
endmodule

