//
// This data structure takes in a multi-word data and serializes
// it to a single word output.
//
// The input channel handshake is a ready-and-valid interface
// and the output channel handshake is a valid-then-yumi
// interface. This makes both channels "helpful" style
// handshakes.
//
// There are two options for this module:
//     1) zero bubbles, no dependence, 2 element buffer for last data word
//     2) one bubble, no dependence, 1 element buffer for last data word
// By default option 1 is used, option 2 can be enabled by setting
// use_minimal_buffering_p = 1
//

`include "bsg_defines.v"

module bsg_parallel_in_serial_out 

   #(parameter width_p                 = -1
    ,parameter els_p                   = -1
    ,parameter hi_to_lo_p              = 0 // sending from high bits to low bits
    ,parameter use_minimal_buffering_p = 0 // using single element buffer
    )

    (input                           clk_i
    ,input                           reset_i

    // Data Input Channel (Ready and Valid)
    ,input                           valid_i
    ,input  [els_p-1:0][width_p-1:0] data_i
    ,output                          ready_and_o

    // Data Output Channel (Valid then Yumi)
    ,output                          valid_o
    ,output            [width_p-1:0] data_o
    ,input                           yumi_i
    );

    // Reverse the input data array if send from HI to LO
    logic [els_p-1:0][width_p-1:0] data_li;
    if (hi_to_lo_p == 0)
      begin: lo2hi
        assign data_li = data_i;
      end
    else
      begin: hi2lo
        bsg_array_reverse 
       #(.width_p(width_p)
        ,.els_p(els_p)
        ) bar
        (.i(data_i)
        ,.o(data_li)
        );
      end

    /**
     * Buffering the LAST input data word
     *
     * By default a two-element fifo is used to eleminate bubbling.
     * One-element fifo is optional for minimal resource utilization.
     */
    logic fifo0_ready_lo, fifo_v_li;
    logic fifo_v_lo, fifo0_yumi_li;
    logic [els_p-1:0][width_p-1:0] fifo_data_lo;

    if (use_minimal_buffering_p == 0)
      begin: two_fifo
        bsg_two_fifo
       #(.width_p(width_p)
        ) fifo0
        (.clk_i  (clk_i)
        ,.reset_i(reset_i)
        ,.ready_o(fifo0_ready_lo)
        ,.data_i (data_li[els_p-1])
        ,.v_i    (fifo_v_li)
        ,.v_o    (fifo_v_lo)
        ,.data_o (fifo_data_lo[els_p-1])
        ,.yumi_i (fifo0_yumi_li)
        );
      end
    else
      begin: one_fifo
        bsg_one_fifo
       #(.width_p(width_p)
        ) fifo0
        (.clk_i  (clk_i)
        ,.reset_i(reset_i)
        ,.ready_o(fifo0_ready_lo)
        ,.data_i (data_li[els_p-1])
        ,.v_i    (fifo_v_li)
        ,.v_o    (fifo_v_lo)
        ,.data_o (fifo_data_lo[els_p-1])
        ,.yumi_i (fifo0_yumi_li)
        );
      end

  if (els_p == 1) 
  begin: bypass

    // When conversion ratio is 1, only one data word exists
    // Connect fifo0 signals directly to input/output ports

    assign fifo_v_li     = valid_i;
    assign ready_and_o   = fifo0_ready_lo;

    assign valid_o       = fifo_v_lo;
    assign data_o        = fifo_data_lo;
    assign fifo0_yumi_li = yumi_i;

  end 
  else 
  begin: piso

    /**
     * Buffering the rest of the data words
     *
     * Single element buffering is sufficient for bubble-free transmission.
     *
     * Output data of fifo1 is guaranteed to be valid if output data of fifo0 is 
     * valid and shift_ctr_r != (els_p-1).
     * Therefore v_o signal of fifo1 is unused to minimize hardware utilization.
     */
    logic fifo1_ready_lo, fifo1_yumi_li;

    bsg_one_fifo
   #(.width_p((els_p-1)*width_p)
    ) fifo1
    (.clk_i  (clk_i)
    ,.reset_i(reset_i)
    ,.ready_o(fifo1_ready_lo)
    ,.data_i (data_li[els_p-2:0])
    ,.v_i    (fifo_v_li)
    ,.v_o    ()
    ,.data_o (fifo_data_lo[els_p-2:0])
    ,.yumi_i (fifo1_yumi_li)
    );

    /**
     * Enqueue data into fifo iff both fifos are ready
     */
    assign ready_and_o = fifo0_ready_lo & fifo1_ready_lo;
    assign fifo_v_li = valid_i & ready_and_o;

    /**
     * Data fifo yumi signals
     *
     * Dequeue from fifo1 when second-last data word has been sent out, freeing
     * space for the following data words to avoid bubbling.
     * Dequeue from fifo0 when last data word has been sent out, indicating
     * done of transmission.
     */
    localparam clog2els_lp = $clog2(els_p);
    logic [clog2els_lp-1:0] shift_ctr_r;

    assign fifo0_yumi_li = (shift_ctr_r == clog2els_lp ' (els_p-1)) && yumi_i;
    assign fifo1_yumi_li = (shift_ctr_r == clog2els_lp ' (els_p-2)) && yumi_i;

    /**
     * Shift Counter Logic
     *
     * The shift_ctr_r register stores the word we are transmitting. Whenever
     * we reset or done transmitting data, we clear the shift_ctr_r register.
     * When data fifo has valid data output, we will increment the register if 
     * the outside world is going to accept our data (ie. yumi_i).
     *
     * Possible optimization
     *
     * Can instead use bsg_counter_clear_up_one_hot and one-hot mux down below
     * for faster hardware by getting rid of a comparator and decoder on the paths.
     * The downside is that there are more registers for counter (N vs lgN).
     * Can do some PPA analysis for the tradeoff.
     */
    bsg_counter_clear_up
   #(.max_val_p (els_p-1)
    ,.init_val_p('0)
    ) shift_ctr
    (.clk_i     (clk_i)
    ,.reset_i   (reset_i)
    ,.clear_i   (fifo0_yumi_li)
    ,.up_i      (~fifo0_yumi_li & yumi_i)
    ,.count_o   (shift_ctr_r)
    );

    /**
     * Valid Output Signal
     *
     * The valid_o signal means the output data is valid. For this
     * module, the output is valid iff data fifo has valid output data.
     */
    assign valid_o = fifo_v_lo;

    /**
     * Data Output Signal
     *
     * Assign data_o to the word that we have shifted to.
     */
    bsg_mux
   #(.width_p(width_p)
    ,.els_p  (els_p)
    ) data_o_mux
    (.data_i (fifo_data_lo)
    ,.sel_i  (shift_ctr_r)
    ,.data_o (data_o)
    );

  end

endmodule
