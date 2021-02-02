
//
// Paul Gao 02/2021
//
//

module bsg_link_source_sync_upstream_sync

 #(parameter width_p                         = "inv"
  ,parameter lg_fifo_depth_p                 = 3
  ,parameter lg_credit_to_token_decimation_p = 1
  )

  (// control signals  
   input                clk_i
  ,input                reset_i
  ,input                async_token_reset_i
  // input from core
  ,input                v_i
  ,input  [width_p-1:0] data_i
  ,output               ready_o
  // output to PHY
  ,output               v_o
  ,output [width_p-1:0] data_o
  ,input                token_clk_i
  );

  // asserted when fifo has valid data and token credit is available
  logic v_n;
  assign v_o    = (reset_i)? '0 : v_n;
  assign data_o = (reset_i)? '0 : data_i;

  // we need to track whether the credits are coming from
  // posedge or negedge tokens.

  // high bit indicates which counter we are grabbing from
  logic [lg_credit_to_token_decimation_p+1-1:0] token_alternator_r;

  // Increase token alternator when dequeue from async fifo
  bsg_counter_clear_up 
 #(.max_val_p({(lg_credit_to_token_decimation_p+1){1'b1}})
  ,.init_val_p(0) // this will start us on the posedge token
  ,.disable_overflow_warning_p(1) // Allow overflow for this counter
  )
  token_alt
  (.clk_i  (clk_i)
  ,.reset_i(reset_i)
  ,.clear_i(1'b0)
  ,.up_i   (v_n)
  ,.count_o(token_alternator_r)
  );

  // high bit set means we have exceeded number of posedge credits
  // and are doing negedge credits
  wire on_negedge_token = token_alternator_r[lg_credit_to_token_decimation_p];

  logic negedge_credits_avail, posedge_credits_avail;

  wire credit_avail = on_negedge_token
       ? negedge_credits_avail
       : posedge_credits_avail;

  // we send if we have both data to send and credits to send with
  assign v_n = credit_avail & v_i;
  assign ready_o = (reset_i)? 1'b1 : credit_avail;

  wire negedge_credits_deque = v_n & on_negedge_token;
  wire posedge_credits_deque = v_n & ~on_negedge_token;

  // **********************************************
  // token channel
  //
  // these are tokens coming from off chip that need to
  // cross into the io clock domain.
  //
  // note that we are a little unconventional here; we use the token
  // itself as a clock. this because we don't know the phase of the
  // token signal coming in.
  //
  // we count both edges of the token separately, and assume that they
  // will alternate in lock-step. we use two separate counters to do this.
  //
  // an alternative would be to use
  // dual-edged flops, but they are not available in most ASIC libraries
  // and although you can synthesize these out of XOR'd flops, they
  // violate the async maxim that all signals crossing clock boundaries
  // must come from a launch flop.

  bsg_async_credit_counter
    #(// half the credits will be positive edge tokens
      .max_tokens_p(2**(lg_fifo_depth_p-1-lg_credit_to_token_decimation_p))
      ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
      ,.count_negedge_p(1'b0)
      // we enable extra margin in case downstream module wants more tokens
      ,.extra_margin_p(2)
      ,.start_full_p(1)
      ,.use_async_w_reset_p(1'b1)
      ) pos_credit_ctr
      (
       .w_clk_i   (token_clk_i)
       ,.w_inc_token_i(1'b1)
       ,.w_reset_i(async_token_reset_i)

       // the I/O clock domain is responsible for tabulating tokens
       ,.r_clk_i             (clk_i                )
       ,.r_reset_i           (reset_i              )
       ,.r_dec_credit_i      (posedge_credits_deque)
       ,.r_infinite_credits_i(1'b0                 )
       ,.r_credits_avail_o   (posedge_credits_avail)
       );

  bsg_async_credit_counter
    #(// half the credits will be negative edge tokens
      .max_tokens_p(2**(lg_fifo_depth_p-1-lg_credit_to_token_decimation_p))
      ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
      ,.count_negedge_p(1'b1)
      // we enable extra margin in case downstream module wants more tokens
      ,.extra_margin_p(2)
      ,.start_full_p(1)
      ,.use_async_w_reset_p(1'b1)
      ) neg_credit_ctr
      (
       .w_clk_i   (token_clk_i)
       ,.w_inc_token_i(1'b1)
       ,.w_reset_i(async_token_reset_i)

       // the I/O clock domain is responsible for tabulating tokens
       ,.r_clk_i             (clk_i                )
       ,.r_reset_i           (reset_i              )
       ,.r_dec_credit_i      (negedge_credits_deque)
       ,.r_infinite_credits_i(1'b0                 )
       ,.r_credits_avail_o   (negedge_credits_avail)
       );


endmodule