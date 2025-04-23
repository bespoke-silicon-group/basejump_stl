/**
 *  bsg_serial_in_parallel_out_full.sv
 *
 *  This module is a serial in parallel out module with a constant in/out ratio. 
 *  The implementation is much simpler than bsg_serial_in_parallel_out.sv, presumably
 *  leading to better timing and less area and power.
 *
 *  This module is like bsg_serial_in_parallel_out_passthru, except that it buffers
 *  data with FIFOs and introduces one cycle of extra latency beyond the in/out ratio.
 *
 *  Output is only valid, when the output array is fully assembled.
 *
 *  This module allows for the setting of extra_buffers_p, which allows for more
 *  than minimum number of buffers. If this is set to 0, there will be 1-cycle bubbles
 *  between parallel deques. By default, extra_buffers_p is set to 1, which allows 
 *  for no bubbles during standard propagation. The value may also be set to a greater number,
 *  to allow for greater amounts of buffering.
 *
 *  The module currently does not support extra_buffers_p > els_p.
 *
 *  use_minimal_buffering_p is a backwards compatible interface that sets extra_buffers_p to 0
 *  it is ignored if extra_buffers_p is also set.
 *
 *  @author tommy   02/2019
 *  Paul Gao        06/2019
 *
 * BaseJump 3.0 suggestion: rename to bsg_serial_in_parallel_out_const
 */

`include "bsg_defines.sv"

module bsg_serial_in_parallel_out_full

 #(parameter `BSG_INV_PARAM(width_p)
   ,parameter `BSG_INV_PARAM(els_p)
  ,parameter hi_to_lo_p              = 0
  ,parameter use_minimal_buffering_p = 0
  ,parameter extra_buffers_p         = (use_minimal_buffering_p ? 0 : 1)
  )
  
  (input clk_i
  ,input reset_i

  ,input                                 v_i
  ,output logic                          ready_and_o
  ,input [width_p-1:0]                   data_i

  ,output logic [els_p-1:0][width_p-1:0] data_o
  ,output logic                          v_o
  ,input                                 yumi_i
  );

`ifndef BSG_HIDE_FROM_SYNTHESIS 
  initial
   assert (extra_buffers_p <= els_p)
    else $error("%m bsg_serial_in_parallel_out_full does not support extra_buffers_p (%d) > els_p (%d)",extra_buffers_p, els_p);
`endif
    
  localparam lg_els_lp = `BSG_SAFE_CLOG2(els_p);
   
  // If send hi_to_lo, reverse the output data array
  logic [els_p-1:0][width_p-1:0] data_lo;

  if (hi_to_lo_p == 0)
    begin: lo2hi
      assign data_o = data_lo;
    end
  else
    begin: hi2lo
      bsg_array_reverse
     #(.width_p(width_p)
      ,.els_p(els_p)
      ) bar
      (.i(data_lo)
      ,.o(data_o)
      );
    end
    

  logic [els_p-1:0] fifo_valid_li, fifo_ready_and_lo;
  logic [els_p-1:0] fifo_valid_lo;

  // Full array is valid when all fifos have valid data
  assign v_o = & fifo_valid_lo;
  
  // Push received data into fifos in round-robin way
  bsg_round_robin_1_to_n 
 #(.num_out_p(els_p)
  ) brr
  (.clk_i      (clk_i)
  ,.reset_i    (reset_i)
  ,.valid_i    (v_i)
  ,.ready_and_o(ready_and_o)
  ,.valid_o    (fifo_valid_li)
  ,.ready_and_i(fifo_ready_and_lo)
  );

  // Data fifos
  genvar i;
  
  for (i = 0; i < els_p; i++) 
  begin: fifos
    // Lowest word fifo selection depends on use_minimal_buffering_p
   if (i < extra_buffers_p)  //(i == 0 && use_minimal_buffering_p == 0)
      begin: twofifo
        // Use two element fifo to avoid bubble
        bsg_two_fifo
        #(.width_p(width_p)
        ) fifo
        (.clk_i         (clk_i)
        ,.reset_i       (reset_i)

        ,.ready_param_o (fifo_ready_and_lo[i])
        ,.data_i        (data_i)
        ,.v_i           (fifo_valid_li[i])

        ,.v_o           (fifo_valid_lo[i])
        ,.data_o        (data_lo[i])
        ,.yumi_i        (yumi_i)
        );
      end
    else
      begin: onefifo
        // Use one element fifo to minimize hardware
        bsg_one_fifo
        #(.width_p(width_p)
        ) fifo
        (.clk_i      (clk_i)
        ,.reset_i    (reset_i)

        ,.ready_and_o(fifo_ready_and_lo[i])
        ,.data_i     (data_i)
        ,.v_i        (fifo_valid_li[i])

        ,.v_o        (fifo_valid_lo[i])
        ,.data_o     (data_lo[i])
        ,.yumi_i     (yumi_i)
        );
      end
  end

endmodule

`BSG_ABSTRACT_MODULE(bsg_serial_in_parallel_out_full)

