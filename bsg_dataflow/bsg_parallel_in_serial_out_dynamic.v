/**
 *  bsg_parallel_in_serial_out_dynamic.v
 *
 *  Paul Gao        12/2020
 *
 */

`include "bsg_defines.v"

module bsg_parallel_in_serial_out_dynamic

 #(parameter width_p          = "inv"
  ,parameter max_els_p        = "inv"
  ,parameter lg_max_els_lp    = `BSG_SAFE_CLOG2(max_els_p)
  )

  (input clk_i
  ,input reset_i

  // Input side
  ,input                               v_i
  ,input  [lg_max_els_lp-1:0]          len_i
  ,input  [max_els_p-1:0][width_p-1:0] data_i
  ,output                              ready_o

  // Output side
  ,output                              v_o
  ,output                              len_v_o
  ,output [width_p-1:0]                data_o
  ,input                               yumi_i
  );

  // Go fifo
  // Store last data word of upcoming packet into the 2-element fifo

  logic                              go_fifo_v_li, go_fifo_ready_lo;
  logic                              go_fifo_v_lo, go_fifo_yumi_li;
  logic [width_p-1:0]                go_fifo_data_li;
  logic [lg_max_els_lp-1:0]          len_lo;
  logic [max_els_p-1:0][width_p-1:0] fifo_data_lo;

  bsg_two_fifo
 #(.width_p(lg_max_els_lp+width_p              )
  ) go_fifo
  (.clk_i  (clk_i                              )
  ,.reset_i(reset_i                            )

  ,.ready_o(go_fifo_ready_lo                   )
  ,.data_i ({len_i, data_i[len_i]             })
  ,.v_i    (go_fifo_v_li                       )

  ,.v_o    (go_fifo_v_lo                       )
  ,.data_o ({len_lo, fifo_data_lo[max_els_p-1]})
  ,.yumi_i (go_fifo_yumi_li                    )
  );

  if (max_els_p == 1) 
  begin: bypass

    // When conversion ratio is 1, only one data word exists
    // Connect go_fifo signals directly to input/output ports

    assign go_fifo_v_li    = v_i;
    assign ready_o         = go_fifo_ready_lo;

    assign v_o             = go_fifo_v_lo;
    assign data_o          = fifo_data_lo;
    assign go_fifo_yumi_li = yumi_i;

  end 
  else 
  begin: piso

    // Data fifo
    // Store the rest of the data words into one-element fifo
    logic data_fifo_v_li, data_fifo_ready_lo;
    logic data_fifo_v_lo, data_fifo_yumi_li;

    bsg_one_fifo
   #(.width_p((max_els_p-1)*width_p      )
    ) data_fifo
    (.clk_i  (clk_i                      )
    ,.reset_i(reset_i                    )

    ,.ready_o(data_fifo_ready_lo         )
    ,.data_i (data_i[max_els_p-2:0]      )
    ,.v_i    (data_fifo_v_li             )

    ,.v_o    (data_fifo_v_lo             )
    ,.data_o (fifo_data_lo[max_els_p-2:0])
    ,.yumi_i (data_fifo_yumi_li          )
    );

    // Enqueue data packet when both fifos are ready
    // To ensure continuous transmission, zero_length packets are not
    // pushed into data_fifo
    assign go_fifo_v_li   = v_i & ready_o;
    assign data_fifo_v_li = v_i & ready_o & ~(len_i == (lg_max_els_lp)'(0));
    assign ready_o        = go_fifo_ready_lo & data_fifo_ready_lo;

    logic [lg_max_els_lp-1:0] count_r, count_lo;
    logic clear_li, up_li;
    logic count_r_is_zero, count_r_is_second_last, count_r_is_last;

    // fix evaluate to Z problem in simulation
    assign count_lo = count_r;

    // When using len_lo signal, always AND with go_fifo_v_lo to eliminate
    // possible zero-pessimism problem in simulation
    assign count_r_is_zero = (count_lo == lg_max_els_lp'(0));
    assign count_r_is_second_last = go_fifo_v_lo & (count_lo == (len_lo - lg_max_els_lp'(1));
    assign count_r_is_last = go_fifo_v_lo & (count_lo == len_lo);

    // Indicate if output word is first word of packet
    assign len_v_o = count_r_is_zero;

    // Count up if current word is not last word of packet.
    assign up_li = yumi_i & ~count_r_is_last;

    // Clear counter when whole packet finish sending
    assign clear_li = yumi_i & count_r_is_last;

    // Pop go_fifo after transmission of whole packet
    // Pop data_fifo only for non-zero-length packet, after transmissing 
    // second-last data word of packet
    assign go_fifo_yumi_li = clear_li;
    assign data_fifo_yumi_li = yumi_i & count_r_is_second_last;

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

    // Data output
    // Last data word is stored in the two-element fifo
    assign v_o    = go_fifo_v_lo;
    assign data_o = count_r_is_last? fifo_data_lo[max_els_p-1] : fifo_data_lo[count_lo];

  end


/*
  // Go fifo
  bsg_two_fifo
 #(.width_p(lg_max_els_lp+width_p)
  ) go_fifo
  (.clk_i  (clk_i                    )
  ,.reset_i(reset_i                  )

  ,.ready_o(go_fifo_ready_lo         )
  ,.data_i ({len_i, data_i[0]}       )
  ,.v_i    (go_fifo_v_li             )

  ,.v_o    (go_fifo_v_lo             )
  ,.data_o ({len_lo, fifo_data_lo[0]})
  ,.yumi_i (go_fifo_yumi_li          )
  );
  
  if (max_els_p == 1) 
  begin: bypass

    // When conversion ratio is 1, only one data word exists
    // Connect go_fifo signals directly to input/output ports

    assign go_fifo_v_li    = v_i;
    assign ready_o         = go_fifo_ready_lo;

    assign v_o             = go_fifo_v_lo;
    assign data_o          = fifo_data_lo;
    assign go_fifo_yumi_li = yumi_i;

  end 
  else 
  begin: piso
  
    logic data_fifo_v_li, data_fifo_ready_lo;
    logic data_fifo_v_lo, data_fifo_yumi_li;
  
    logic lastword_fifo_v_lo, lastword_fifo_yumi_li;
    logic [width_p-1:0] lastword_fifo_data_lo;
  
    assign go_fifo_v_li   = v_i & ready_o;
    assign data_fifo_v_li = v_i & ready_o & ~(len_i == (lg_max_els_lp)'(0));
    assign ready_o        = go_fifo_ready_lo & data_fifo_ready_lo;

    // Data fifo
    bsg_one_fifo
   #(.width_p((max_els_p-1)*width_p      )
    ) data_fifo
    (.clk_i  (clk_i                      )
    ,.reset_i(reset_i                    )
  
    ,.ready_o(data_fifo_ready_lo         )
    ,.data_i (data_i[max_els_p-1:1]      )
    ,.v_i    (data_fifo_v_li             )
  
    ,.v_o    (data_fifo_v_lo             )
    ,.data_o (fifo_data_lo[max_els_p-1:1])
    ,.yumi_i (data_fifo_yumi_li          )
    );
    
    // Last Word fifo
    bsg_one_fifo
   #(.width_p(width_p               )
    ) lastword_fifo
    (.clk_i  (clk_i                 )
    ,.reset_i(reset_i               )
  
    ,.ready_o(                      )
    ,.data_i (fifo_data_lo[len_lo]  )
    ,.v_i    (data_fifo_yumi_li     )
  
    ,.v_o    (lastword_fifo_v_lo    )
    ,.data_o (lastword_fifo_data_lo )
    ,.yumi_i (lastword_fifo_yumi_li )
    );
    
    logic [lg_max_els_lp-1:0] count_r, count_lo;
    logic clear_li, up_li;
    logic zero_len, count_r_is_zero, count_r_next_is_last, count_r_is_last;
    
    // fix evaluate to Z problem in simulation
    assign count_lo = count_r;
  
    assign zero_len = go_fifo_v_lo & ~data_fifo_v_lo;
    assign count_r_is_zero = (count_lo == lg_max_els_lp'(0));
    assign count_r_next_is_last = ~lastword_fifo_v_lo & (go_fifo_v_lo & (count_lo == (len_lo - lg_max_els_lp'(1)));
    assign count_r_is_last = lastword_fifo_v_lo | zero_len;
    
    // Indicate if output word is first word of packet
    assign len_v_o = count_r_is_zero;
    
    // Count up if current word is not last word of packet.
    assign up_li = yumi_i & ~count_r_is_last;
    
    // Clear counter when whole packet finish sending
    assign clear_li = yumi_i & count_r_is_last;
    
    assign go_fifo_yumi_li = yumi_i & (zero_len | count_r_next_is_last);
    assign data_fifo_yumi_li = yumi_i & count_r_next_is_last;
    assign lastword_fifo_yumi_li = yumi_i & lastword_fifo_v_lo;
    
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
    
    // Output data
    assign v_o    = go_fifo_v_lo | lastword_fifo_v_lo;
    assign data_o = lastword_fifo_v_lo? lastword_fifo_data_lo : fifo_data_lo[count_lo];
  
  end
*/
endmodule