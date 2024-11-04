/**
 *  bsg_serial_in_parallel_out_passthrough
 *
 *  This module is a serial in parallel out module with a constant in/out ratio. 
 *  The implementation is much simpler than bsg_serial_in_parallel_out.sv, presumably
 *  leading to better timing and less area and power.
 *
 *  This module is like bsg_serial_in_parallel_out_full, except that it uses registers to buffer
 *  data and does not introduce an extra cycle of latency beyond the in/out ratio.
 *  v_o and data_o depend combinationally on v_i and data_i.
 *
 *  Output is only valid, when the output array is fully assembled.
 *
 * BaseJump 3.0 suggestion: rename to bsg_serial_in_parallel_out_const_passthrough
 */

`include "bsg_defines.sv"

module bsg_serial_in_parallel_out_passthrough
 #(parameter `BSG_INV_PARAM(width_p)
   , parameter `BSG_INV_PARAM(els_p)
   , hi_to_lo_p = 0
   )
  (input                                  clk_i
  , input                                 reset_i
     
  , input                                 v_i
  , output logic                          ready_and_o
  , input [width_p-1:0]                   data_i

  , output logic [els_p-1:0][width_p-1:0] data_o
  , output logic                          v_o
  , input                                 ready_and_i
  );
  
  localparam lg_els_lp = `BSG_SAFE_CLOG2(els_p);
   
  logic [els_p-1:0] count_r;

  assign v_o = v_i & count_r[els_p-1];     // means we received all of the words
  assign ready_and_o = ~count_r[els_p-1] | ready_and_i; // have space, or we are dequeing; (one gate delay in-to-out)

  wire sending   = v_o & ready_and_i;  // we have all the items, and downstream is ready
  wire receiving = v_i & ready_and_o;  // data is coming in, and we have space

  // counts one hot, from 0 to width_p
  // contains one hot pointer to word to write to
  // simultaneous restart and increment are allowed

  if (els_p == 1)
    begin : single_word
      assign count_r = 1'b1;
    end
  else
    begin : multi_word
      bsg_counter_clear_up_one_hot
       #(.max_val_p(els_p-1))
       bcoh
        (.clk_i(clk_i)
         ,.reset_i(reset_i)
         ,.clear_i(sending)
         ,.up_i(receiving & ~count_r[els_p-1])
         ,.count_r_o(count_r)
         );
    end

  logic [els_p-1:0][width_p-1:0] data_lo;

  for (genvar i = 0; i < els_p-1; i++)
    begin: rof
      wire my_turn = v_i & count_r[i];
      bsg_dff_en #(.width_p(width_p)) dff
      (.clk_i
       ,.data_i
       ,.en_i   (my_turn)
       ,.data_o (data_lo [i])
      );
    end
  assign data_lo[els_p-1] = data_i;

  // If send hi_to_lo, reverse the output data array
  if (hi_to_lo_p == 0)
    begin: lo2hi
      assign data_o = data_lo;
    end
  else
    begin: hi2lo
      bsg_array_reverse
       #(.width_p(width_p), .els_p(els_p))
       bar
        (.i(data_lo)
         ,.o(data_o)
         );
    end


endmodule

`BSG_ABSTRACT_MODULE(bsg_serial_in_parallel_out_passthrough)
