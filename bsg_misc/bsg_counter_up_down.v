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
// it can also precompute a table whether the next value is zero based 
// on all expected combinations of up_i and down_i, and then use
// a four input mux to output the zero value. Then input delay is 
// zero and output delay is a 2-bit 4-input mux. Possibly the
// output logic can be even less than this.
//


module bsg_counter_up_down #(parameter max_val_p   = -1
                             ,parameter init_val_p = -1

                          //localpara
                         ,parameter ptr_width_lp = 
                            `BSG_WIDTH(max_val_p)
                         )
    ( input                           clk_i
    , input                           reset_i

    , input                           up_i
    , input                           down_i

    , output logic [ptr_width_lp-1:0] count_o
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
    if ((count_o==max_val_p) & up_i   & ~reset_i)
		  $display("%m error: counter overflow at time %t", $time);
	  if ((count_o==0)         & down_i & ~reset_i)
		  $display("%m error: counter underflow at time %t", $time);			
  end
//synopsys translate_on				

endmodule
