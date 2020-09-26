//
// This is an up-down counter with initial and max values.
// Even for counters that start at max value, it can be useful
// to specify an even greater max. This is useful in case where you want to
// be able to change the max value after hardware design time,
// for example for credit counters between chips. The
// hardware can return the extra credits right after reset.
//
// PO: a bsg_counter_up_down_blind only says whether the count is
// zero, and does not show the actual value. the blind version
// can latch the up_i and down_i signals, for zero input latency.
// It can also precompute whether the high bits are all 0.
// then it can use two simple expressions,
// wire [1:0] same_dec = { up_r ^ down_r, down_r & ~up_r };
// wire [1:0] one_zero     = { ctr[0] & high_bits_zero_r, ~ctr[0] & high_bits_zero_r };
//
// wire zero_o = (one_zero[0] & same_dec[1]) | (one_zero[1] & same_dec[0]);
//
// alternatively, using four bits, we could output a 2-in, 1-out truth table that
// is indexed by up_r and down_r.
//
// merged bsg_counter_up_down_variable into this module june 2018

`include "bsg_defines.v"

module bsg_counter_up_down #( parameter max_val_p    = -1
                                     , parameter init_val_p   = -1
                                     , parameter max_step_p   = -1

                                     //localpara
                                     , parameter step_width_lp =
                                        `BSG_WIDTH(max_step_p)
                                     , parameter ptr_width_lp =
                                        `BSG_WIDTH(max_val_p))
   ( input                            clk_i
   , input                            reset_i

   , input        [step_width_lp-1:0] up_i
   , input        [step_width_lp-1:0] down_i

   , output logic [ptr_width_lp-1:0]  count_o
    );

// keeping track of number of entries and updating read and
// write pointers, and displaying errors in case of overflow
// or underflow

always_ff @(posedge clk_i)
  begin
    if (reset_i)
			count_o <= init_val_p;
    else
      // It was tested on Design Compiler that using a
      // simple minus and plus operation results in smaller
      // design, rather than using xor or other ideas
      // between down_i and up_i
      count_o <= count_o - down_i + up_i;
  end

//synopsys translate_off
  always_ff @ (negedge clk_i) begin
    if ((count_o==max_val_p) & up_i   & (reset_i === 1'b0))
		  $display("%m error: counter overflow at time %t", $time);
	  if ((count_o==0)         & down_i & (reset_i === 1'b0))
		  $display("%m error: counter underflow at time %t", $time);
  end
//synopsys translate_on

endmodule
