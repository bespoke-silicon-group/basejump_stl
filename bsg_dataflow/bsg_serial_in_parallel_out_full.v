/**
 *  bsg_serial_in_parallel_out_full.v
 *
 *  This is a simpler version of bsg_serial_in_parallel_out.
 *  Output is only valid, when the output array is fully assembled.
 *
 *  By default, this version has zero bubble.
 *  Minimize hardware by setting use_minimal_buffering_p=1, which introduces
 *  1-cycle bubble for every data array received.
 *
 *  @author tommy   02/2019
 *  Paul Gao        06/2019
 *
 */

module bsg_serial_in_parallel_out_full

 #(parameter width_p                 = "inv"
  ,parameter els_p                   = "inv"
  ,parameter hi_to_lo_p              = 0
  ,parameter use_minimal_buffering_p = 0
  )
  
  (input clk_i
  ,input reset_i
    
  ,input                                 v_i
  ,output logic                          ready_o
  ,input [width_p-1:0]                   data_i

  ,output logic [els_p-1:0][width_p-1:0] data_o
  ,output logic                          v_o
  ,input                                 yumi_i
  );
  
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
    

  logic [els_p-1:0] fifo_valid_li, fifo_ready_lo;
  logic [els_p-1:0] fifo_valid_lo;

  // Full array is valid when all fifos have valid data
  assign v_o = & fifo_valid_lo;
  
  // Push received data into fifos in round-robin way
  bsg_round_robin_1_to_n 
 #(.width_p(width_p)
  ,.num_out_p(els_p)
  ) brr
  (.clk_i  (clk_i)
  ,.reset_i(reset_i)
  ,.valid_i(v_i)
  ,.ready_o(ready_o)
  ,.valid_o(fifo_valid_li)
  ,.ready_i(fifo_ready_lo)
  );

  // Data fifos
  genvar i;
  
  for (i = 0; i < els_p; i++) 
  begin: fifos
    // Lowest word fifo selection depends on use_minimal_buffering_p
    if (i == 0 && use_minimal_buffering_p == 0)
      begin: twofifo
        // Use two element fifo to avoid bubble
        bsg_two_fifo
        #(.width_p(width_p)
        ) fifo
        (.clk_i  (clk_i)
        ,.reset_i(reset_i)

        ,.ready_o(fifo_ready_lo[i])
        ,.data_i (data_i)
        ,.v_i    (fifo_valid_li[i])

        ,.v_o    (fifo_valid_lo[i])
        ,.data_o (data_lo[i])
        ,.yumi_i (yumi_i)
        );
      end
    else
      begin: onefifo
        // Use one element fifo to minimize hardware
        bsg_one_fifo
        #(.width_p(width_p)
        ) fifo
        (.clk_i  (clk_i)
        ,.reset_i(reset_i)

        ,.ready_o(fifo_ready_lo[i])
        ,.data_i (data_i)
        ,.v_i    (fifo_valid_li[i])

        ,.v_o    (fifo_valid_lo[i])
        ,.data_o (data_lo[i])
        ,.yumi_i (yumi_i)
        );
      end
  end

endmodule