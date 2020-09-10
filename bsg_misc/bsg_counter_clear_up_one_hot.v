// This counter is a one hot counter; so exactly one output bit is set at all times.
// For example if the value of the counter is zero, then bit 0 will be set.
// This counter makes it extremely fast to detect whether the counter is a particular value.
// The logic is relatively expensive, since it scales with the number of values the counter can take on.
// It is most sensible when you need a decoder to select items in an array, and your access pattern through
// that array is sequential. It will minimize critical paths, and the cost is amortized because the
// alternative is a binary counter and a decoder.
//
// The interface of this counter is analogous to bsg_counter_clear_up:
//
// - the reset_i signal ensures that output to init_val_p; default is 2's complement 0 regardless of up_i or clear_i
// - the clear_i signal sets the 2's complement value to 0 (i.e. all bits except low bit are 0; low bit is 1)
// - the up_i signal increments the counter (corresponds to left rotate). it stacks on top of the clear_i
//   so it is legal for the user to assert both clear_i and up_i simultaneous and the effects of both to be reflected.
//

`include "bsg_defines.v"

module bsg_counter_clear_up_one_hot
  #(parameter max_val_p=-1, width_lp=max_val_p+1, init_val_p=(width_lp) ' (1))
  (input clk_i
   ,input reset_i
   ,input clear_i
   ,input up_i
   ,output [width_lp-1:0] count_r_o
  );
   
  logic [width_lp-1:0] bits_r, bits_n;
  
  always_comb
    begin
      bits_n   = bits_r;
      if (clear_i)
        bits_n = (width_lp) ' (1);
      // increment is a rotate operator
      if (up_i)
        bits_n = { bits_n[width_lp-2:0], bits_n[width_lp-1] };      
      if (reset_i)
        bits_n = (width_lp) ' (init_val_p);
    end
    
  // clock gate, hopefully
  always_ff @(posedge clk_i)
    if (reset_i | up_i | clear_i)
        bits_r <= bits_n;
  
  assign count_r_o = bits_r;
      
endmodule
