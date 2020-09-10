// MBT 7/25/2014
// async credit counter
//
// In this design, there are two clock domains. The first
// clock domain (w_) receives incoming credits. The second
// clock domain (r_) spends the credits. The first clock domain
// never needs to know how many credits are spent; it just
// accumulates how many have been received. This accumulated
// value is passed as a gray-coded pointer across to the _r clock domain.
// The _r clock domain records how many credits have been spent. It starts
// with a negative value. There will be lag from the w_ domain to
// the r_ domain because of the synchronizers. So imagine, after reset,
// we start sending packets, decrementing the credit counter, but no
// credits are received. The _r pointer will advance until it reaches the w_
// pointer, and then avail will go low, and transmits will stop. Then the
// credits start arriving and the w_ is advanced. After a few cycles delay,
// the _r side will observe this change and start spending credits again.
//
// label all signals in this module accordingly:
//
// w_: signals in "receive credits" clock domain
// r_: signals in "spend credits" clock domain
//

// TOKENS vs. CREDITS. We support a feature here, which is the idea of a token.
// A token is worth multiple credits. We pass tokens through the fifo (so that
// the gray-coded values are still consecutive). The number of credits must
// be a power-of-two multiple of the number of tokens. The log of this value is set 
// by lg_credit_to_token_decimation_p. Using tokens can be used to reduce
// the toggle rate of the w_clk_i signal, for example, if it is being run
// over a pin exterior to the chip.
//
// RESET: both resets must be asserted and w_ clock most be posedge (negedge) toggled
// at least once; and the r_ clock posedge toggled at least four times after that.
// This will be a sufficient number of clocks to pass through the synchronizers.
// This will need to be done explicitly for the credit clock.
//
// ASYNC RESET PROCEDURE:
// Step 1: Assert r_ reset.
// Step 2: w_ reset must be posedge/negedge toggled (0->1->0) at least once.
//         w_ clock cannot toggle during this step.
// Step 3: r_ clock posedge toggled at least four times after that.
// Step 4: Deassert r_ reset.
//

// MARGIN: when credit counters are used to count outgoing packets, it is sometimes
// helpful to include extra bits of precision in case the latency is longer than
// expected and the downstream module needs more buffer space than originally planned.
// The downstream module can give back tokens right after reset before anything is sent,
// increasing the amount of margin the upstream module thinks it have. Of course, you
// need to have the flexibility of being able to change the downstream's buffer space
// to take advantage of this feature, but this is the case if the downstream module
// is an FPGA. The parameter extra_margin_p is the number of additional bits in the
// credit counter that should be added to accomodate this behaviour. So for example,
// extra_margin_p of 2 increases the credit capacity by 2X.

// The parameter count_negedge_p determines whether we count
// on negedge edge or positive edge of the clock.

`include "bsg_defines.v"

module bsg_async_credit_counter #(parameter max_tokens_p = "inv"
                                  , parameter lg_credit_to_token_decimation_p = "inv"
                                  , parameter count_negedge_p = 0
                                  , parameter extra_margin_p = 0
                                  , parameter check_excess_credits_p = 1
				  , parameter start_full_p = 1
				  , parameter use_async_w_reset_p = 0)
    (
      input w_clk_i
    , input w_inc_token_i
    , input w_reset_i
    , input r_clk_i
    , input r_reset_i
    , input r_dec_credit_i
    , input r_infinite_credits_i  // basically suppress this module
    , output r_credits_avail_o
    );

   // $clog2(x) is how many bits are required to represent
   // x unique values. we need to represent 0..max_credits_p = max_credits_p+1 values.

   localparam r_counter_width_lp = extra_margin_p+$clog2(max_tokens_p+1) + lg_credit_to_token_decimation_p;
   localparam w_counter_width_lp = extra_margin_p+$clog2(max_tokens_p+1);

   logic [r_counter_width_lp-1:0] r_counter_r;
   logic [w_counter_width_lp-1:0] w_counter_gray_r, w_counter_gray_r_rsync, w_counter_binary_r_rsync;

   always @(posedge r_clk_i)
     if (r_reset_i)
       // fixme? not sure this constant will always do as expected
       r_counter_r       <= { -max_tokens_p * start_full_p, { lg_credit_to_token_decimation_p  {1'b0} } };
     else
       r_counter_r       <= r_counter_r + r_dec_credit_i;

   // *********** this is basically an async_ptr: begin factor

   bsg_async_ptr_gray #(.lg_size_p(w_counter_width_lp)
                        ,.use_negedge_for_launch_p(count_negedge_p)
                        ,.use_async_reset_p(use_async_w_reset_p)) bapg
   (.w_clk_i(w_clk_i)
    ,.w_reset_i(w_reset_i)
    ,.w_inc_i(w_inc_token_i)
    ,.r_clk_i(r_clk_i)
    ,.w_ptr_binary_r_o() // we don't care about the binary version of the ptr on w side
    ,.w_ptr_gray_r_o(w_counter_gray_r)             // synchronized with w clock domain
    ,.w_ptr_gray_r_rsync_o(w_counter_gray_r_rsync) // synchronized with r clock domain
    );

/*
    previously, we converted w_counter to binary, appended lg_credit_to_token_decimation 1'b0's and compared them
    but instead, we convert the other way now.
    assign r_credits_avail_o = r_infinite_credits_i | ~(w_counter_binary_r_rsync_padded == r_counter_r);
*/

   wire [w_counter_width_lp-1:0] r_counter_r_hi_bits         =   r_counter_r[lg_credit_to_token_decimation_p+:w_counter_width_lp];
   wire                          r_counter_r_lo_bits_nonzero = | r_counter_r[0+:lg_credit_to_token_decimation_p];
   wire [w_counter_width_lp-1:0] r_counter_r_hi_bits_gray    = (r_counter_r_hi_bits >> 1) ^ r_counter_r_hi_bits;

   assign r_credits_avail_o = r_infinite_credits_i | r_counter_r_lo_bits_nonzero | (r_counter_r_hi_bits_gray != w_counter_gray_r_rsync);


   // ***************************************
   //  for debug
   //
   //


   // synopsys translate_off

   bsg_gray_to_binary #(.width_p(w_counter_width_lp)) bsg_g2b
     (.gray_i(w_counter_gray_r_rsync)
      ,.binary_o(w_counter_binary_r_rsync)
      );

   wire [r_counter_width_lp-1:0]  w_counter_binary_r_rsync_padded = { w_counter_binary_r_rsync, { lg_credit_to_token_decimation_p {1'b0 } }};

   wire  [r_counter_width_lp-1:0] r_free_credits =  w_counter_binary_r_rsync_padded - r_counter_r;

   logic [r_counter_width_lp-1:0] r_free_credits_r;

   always @(posedge r_clk_i)
     r_free_credits_r <= r_free_credits;

   if (check_excess_credits_p)
     always @(r_free_credits_r)
       assert(r_reset_i
              |  r_infinite_credits_i
              | (r_free_credits_r <= (max_tokens_p << lg_credit_to_token_decimation_p)))
              else $error("too many credits in credit counter %d (> %3d)"
                          , r_free_credits_r
                          , max_tokens_p << lg_credit_to_token_decimation_p
                          );

   always @(negedge r_clk_i)
       assert (!(r_dec_credit_i===1 && r_credits_avail_o===0))
              else $error("decrementing empty credit counter");

   // synopsys translate_on

   //
   // end debug
   //
   // ****************************************

endmodule
