/**
 *  bsg_serial_in_parallel_out_full_buffered.v
 *
 *  This is a simpler version of bsg_serial_in_parallel_out.
 *  Output is only valid, when the output vector is fully assembled.
 *  This version has zero bubble.
 *
 */

module bsg_serial_in_parallel_out_full_buffered

 #(parameter width_p     = "inv"
  ,parameter els_p       = "inv"
  ,parameter hi_to_lo_p  = 0
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
  
  genvar i;
  
  
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
    
    
  logic [lg_els_lp-1:0] counter_r, counter_lo;
  // fix bsg_decode evaluate to Z in simulation
  assign counter_lo = counter_r;
  
  logic [els_p-1:0] fifo_valid_li, fifo_ready_lo;
  logic [els_p-1:0] fifo_valid_lo;
  
  assign ready_o = fifo_ready_lo[counter_lo];
  assign v_o     = & fifo_valid_lo;
  
  bsg_decode_with_v
 #(.num_out_p(els_p)
  ) bd
  (.i  (counter_lo)
  ,.v_i(v_i)
  ,.o  (fifo_valid_li)
  );
  
  
  for (i = 0; i < els_p; i++) 
  begin: fifos
  
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
  
  
  logic clear_lo, up_lo;
  
  always_comb 
  begin
    clear_lo  = 1'b0;
    up_lo   = 1'b0;
    if (v_i & ready_o)
        if (counter_lo == els_p-1)
            clear_lo = 1'b1;
        else
            up_lo = 1'b1;
  end
  
  bsg_counter_clear_up 
 #(.max_val_p (els_p-1)
  ,.init_val_p(0)
  ) counter
  (.clk_i  (clk_i)
  ,.reset_i(reset_i)
  ,.clear_i(clear_lo)
  ,.up_i   (up_lo)
  ,.count_o(counter_r)
  );

endmodule