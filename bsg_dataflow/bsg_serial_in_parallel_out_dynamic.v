/**
 *  bsg_serial_in_parallel_out_dynamic.v
 *
 *  Paul Gao        06/2019
 *
 */

`include "bsg_defines.v"

module bsg_serial_in_parallel_out_dynamic
                               
 #(parameter width_p          = "inv"
  ,parameter max_els_p        = "inv"
  ,parameter lg_max_els_lp    = `BSG_SAFE_CLOG2(max_els_p)
  )
  
  (input clk_i
  ,input reset_i
  
  // Input side
  ,input                               v_i
  ,input  [lg_max_els_lp-1:0]          len_i
  ,input  [width_p-1:0]                data_i
  ,output                              ready_o
  ,output                              len_ready_o
  
  // Output side
  ,output                              v_o
  ,output [max_els_p-1:0][width_p-1:0] data_o
  ,input                               yumi_i
  );

  genvar i;
  
  logic yumi_lo;
  assign yumi_lo = v_i & ready_o;
  
  logic [lg_max_els_lp-1:0] count_r, count_lo, len_r, len_lo;
  logic clear_li, up_li, dff_en_li, go_fifo_v_li;
  logic count_r_is_zero, count_r_is_last;
  
  // fix evaluate to Z problem in simulation
  assign count_lo = count_r;
  
  // When new packet coming, use new length, otherwise use registered length
  assign len_lo = (count_r_is_zero)? len_i : len_r;
  
  assign count_r_is_zero = (count_lo == lg_max_els_lp'(0));
  assign count_r_is_last = (count_lo == len_lo           );
  
  // We accept new length when first word comes in
  // At this time, counter is at initial value 0
  assign len_ready_o = count_r_is_zero;
  
  // Count up if data word is not last word of current packet.
  assign up_li = yumi_lo & ~count_r_is_last;
  
  // Clear counter when it reaches target length
  assign clear_li = yumi_lo & count_r_is_last;
  assign go_fifo_v_li = clear_li;
  
  // Update length register when new packet comes in
  assign dff_en_li = yumi_lo & count_r_is_zero;
  
  // Length counter
  bsg_counter_clear_up
 #(.max_val_p (max_els_p-1)
  ,.init_val_p(0)
  ) ctr
  (.clk_i     (clk_i   )
  ,.reset_i   (reset_i )
  ,.clear_i   (clear_li)
  ,.up_i      (up_li   )
  ,.count_o   (count_r )
  );
  
  // Length register
  bsg_dff_reset_en
 #(.width_p    (lg_max_els_lp)
  ,.reset_val_p(0)
  ) dff_len
  (.clk_i      (clk_i    )
  ,.reset_i    (reset_i  )
  ,.en_i       (dff_en_li)
  ,.data_i     (len_i    )
  ,.data_o     (len_r    )
  );
  
  // Go fifo
  // Notify output side that packet is ready to send
  // Must use two element fifo to match lowest word data fifo!
  logic one_word_lo;
  
  bsg_two_fifo
 #(.width_p(1)
  ) go_fifo
  (.clk_i  (clk_i          )
  ,.reset_i(reset_i        )
  ,.ready_o(/* This fifo has same size of lowest word data fifo
               No need to check ready_o here */)
  ,.data_i (count_r_is_zero) // Indicate whether it is single word packet
  ,.v_i    (go_fifo_v_li   )
  ,.v_o    (v_o            )
  ,.data_o (one_word_lo    )
  ,.yumi_i (yumi_i         )
  );

  logic [max_els_p-1:0] fifo_valid_li, fifo_ready_lo;
  logic [max_els_p-1:0] fifo_valid_lo, fifo_yumi_li;
  
  // Ready signal from selected fifo
  assign ready_o = fifo_ready_lo[count_lo];

  for (i = 0; i < max_els_p; i++)
  begin: rof0
    if (i == 0)
        // Lowest word fifo always dequeue (packet should have at least one word)
        assign fifo_yumi_li[i] = yumi_i;
    else
        // Rest are bsg_one_fifo, only dequeue when they have valid data
        //
        // Corner case: a single-word packet comes in firstly, then a
        // multi-word packet comes. Use one_word_lo to determine whether
        // first packet is one-word or not.
        //
        // Case above can be prevented if we use bsg_one_fifo everywhere, but
        // there will be one-cycle bubble between packets.
        assign fifo_yumi_li[i] = fifo_valid_lo[i] & yumi_i & ~one_word_lo;
  end
  
  // Trigger selected valid signal
  bsg_decode_with_v
 #(.num_out_p(max_els_p)
  ) bdwv
  (.i  (count_lo     )
  ,.v_i(v_i          )
  ,.o  (fifo_valid_li)
  );

  // Data fifos
  for (i = 0; i < max_els_p; i++) 
  begin: fifos
    if (i == 0)
      begin: twofifo
        // Use two element fifo to avoid bubble
        bsg_two_fifo
       #(.width_p(width_p)
        ) fifo
        (.clk_i  (clk_i  )
        ,.reset_i(reset_i)

        ,.ready_o(fifo_ready_lo[i])
        ,.data_i (data_i          )
        ,.v_i    (fifo_valid_li[i])

        ,.v_o    (fifo_valid_lo[i])
        ,.data_o (data_o       [i])
        ,.yumi_i (fifo_yumi_li [i])
        );
      end
    else
      begin: onefifo
        // Must use one element fifo to work correctly!
        bsg_one_fifo
       #(.width_p(width_p)
        ) fifo
        (.clk_i  (clk_i  )
        ,.reset_i(reset_i)

        ,.ready_o(fifo_ready_lo[i])
        ,.data_i (data_i          )
        ,.v_i    (fifo_valid_li[i])

        ,.v_o    (fifo_valid_lo[i])
        ,.data_o (data_o       [i])
        ,.yumi_i (fifo_yumi_li [i])
        );
      end
  end

endmodule