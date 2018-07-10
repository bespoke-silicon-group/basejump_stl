/********************************** TEST RATIONALE *************************

1. STATE SPACE

 There are significant state spaces resulting from the internal FIFOs
 in the module.

2. PARAMETERIZATION

  WIDTH_P  does not affect design internals much. 1,32,33 are fine
  NUM_IN_P affects design internals somewhat. 1,2,3,4 are fine
  REMOTE_CREDITS_P 1,2,3,4,5,6
  LG_CREDIT_DECIMATION_P 0,1,2,3

 ***************************************************************************/

module test_bsg;

   localparam width_lp                = `WIDTH_P;
   localparam num_in_lp               = `NUM_IN_P;
   localparam remote_credits_lp       = `REMOTE_CREDITS_P;
   localparam lg_credit_decimation_lp = `LG_CREDIT_DECIMATION_P;
   localparam asymmetric_lp           = `ASYMMETRIC_P;
   localparam use_pseudo_large_fifo_lp = `USE_PSEUDO_LARGE_FIFO_P;

   localparam cycle_time_lp = 20;

   wire clk;
   wire reset;

   bsg_nonsynth_clock_gen #(  .cycle_time_p(cycle_time_lp)
                              )  clock_gen
     (  .o(clk)  );

   bsg_nonsynth_reset_gen #(  .num_clocks_p     (1)
                              , .reset_cycles_lo_p(1)
                              , .reset_cycles_hi_p(5)
                              )  reset_gen
     (  .clk_i        (clk)
        , .async_reset_o(reset)
        );

   initial
     begin
        /*$monitor("\n@%0t ps: ", $time
         , "test_input_data: %b, test_input_deque: %b"
         , test_input_data, test_input_deque
        , ", test_output_data_1: %b, test_output_deque_1: %b"
         , test_output_data_1, test_output_deque_1);*/

        $display("\n\n\n");
        $display("===========================================================");
        $display("testing bsg_channel_tunnel with ...");
        $display("WIDTH_LP :               %d", width_lp);
        $display("NUM_IN_LP:               %d", num_in_lp);
        $display("REMOTE_CREDITS_LP:       %d", remote_credits_lp);
        $display("LG_CREDIT_DECIMATION_LP: %d", lg_credit_decimation_lp);
        $display("ASYMMETRIC_LP: %d", asymmetric_lp);
        $display("USE_PSEUDO_LARGE_FIFO_LP: %d", use_pseudo_large_fifo_lp);
     end

   localparam tag_width_lp = $clog2(num_in_lp+1);
   localparam tagged_width_lp = tag_width_lp+width_lp;

   wire [1:0][tagged_width_lp-1:0] multi_data;
   wire [1:0]                      multi_valid;
   wire [1:0]                      multi_yumi;

   //   A B  i/o   channels
   wire [1:0][1:0][num_in_lp-1:0][width_lp-1:0] data;
   wire [1:0][1:0][num_in_lp-1:0]               valid;
   wire [1:0][1:0][num_in_lp-1:0]               yumi;

   // instantiate two connected tunnel ends.
   // fixme: add delay elements

   genvar i;

   // AB
   for (i = 0; i < 2; i=i+1)
     begin: rof
        bsg_channel_tunnel #(.width_p(width_lp)
                             ,.num_in_p(num_in_lp)
                             ,.remote_credits_p(remote_credits_lp)
                             ,.lg_credit_decimation_p(lg_credit_decimation_lp)
                             ,.use_pseudo_large_fifo_p(use_pseudo_large_fifo_lp)
                             ) dut
            (.clk_i   (clk)
             ,.reset_i(reset)
             ,.multi_data_i (multi_data [i])
             ,.multi_valid_i(multi_valid[i])
             ,.multi_yumi_o (multi_yumi [i])

             ,.multi_data_o (multi_data [!i])
             ,.multi_valid_o(multi_valid[!i])
             ,.multi_yumi_i (multi_yumi [!i])

             //             AB  I/O
             ,.data_i (data [i][0])
             ,.valid_i(valid[i][0])
             ,.yumi_o (yumi [i][0])

             ,.data_o (data [i][1])
             ,.valid_o(valid[i][1])
             ,.yumi_i (yumi [i][1])
             );
     end

   // for each channel, we have a counter generating data that goes in
   // and a counter checking the value on the way out.

   //    A B  i/o  channel
   wire [1:0][1:0][num_in_lp-1:0] ctr_incr;
   //    A B  i/o  channel
   wire [1:0][1:0][num_in_lp-1:0] [width_lp-1:0] ctr_lo;

   genvar                      j,k;

   int                         a,b,c;

   wire [31:0] cycle, words_received, credits;

   bsg_counter_clear_up #(.max_val_p({ 1'b0, { 32 { 1'b1 }}})
                          ,.init_val_p(0)
                          ) bccu
     (.clk_i(clk)
      ,.reset_i(reset)
      ,.clear_i(1'b0)
      ,.up_i(multi_yumi[0])
      ,.count_o(words_received)
      );

   wire        cred_send = multi_valid[0] & multi_data[0][width_lp+:tag_width_lp] == (tag_width_lp ' (num_in_lp));

   bsg_counter_clear_up #(.max_val_p({ 1'b0, { 32 { 1'b1 }}})
                          ,.init_val_p(0)
                          ) bccu2
     (.clk_i(clk)
      ,.reset_i(reset)
      ,.clear_i(1'b0)
      ,.up_i(multi_valid[0] & (cred_send))
      ,.count_o(credits)
      );

   localparam show_values_lp=0;
   localparam print_skip_lp=1000;

   always @(negedge clk)
     begin
	if (show_values_lp)
        for (a = 0; a < num_in_lp; a=a+1)
          for (b = 0; b < 2; b=b+1)
            for (c = 0; c < 2; c=c+1)
              $display("channel %d, %s %x ",a, (b ? (c ? "*<-" : "<-*") : (c ? "->*" : "*->"))
                       ,ctr_lo[b][c][a]);
	if ((cycle % print_skip_lp) == 0)
          $display("* cycle %d (words %d, credits %d (%f)"
                   ,cycle
                   ,words_received
                   ,credits
                   ,(real'(credits)) / (real ' (words_received)));
     end

   bsg_cycle_counter #(.width_p(32),.init_val_p(0)
                       ) bcc
     (.clk_i(clk)
      ,.reset_i(reset)
      ,.ctr_r_o(cycle)
      );

   // generate some data
   for (i = 0; i < num_in_lp; i++)
     begin: rof2
        // j-> A B
        for (j = 0; j < 2; j++)
          begin: rof3
             // k -> I/O
             for (k = 0; k < 2; k++)
               begin: rof4
                  bsg_counter_up_down
                      #(.max_val_p({ 1'b0, { width_lp {1'b1} }} )
                       ,.init_val_p( (i<<16)+i)
                       ) ctr
                      (.clk_i(clk)
                       ,.reset_i(reset   )
                       ,.up_i   (ctr_incr[j][k][i])
                       ,.down_i (1'b0    )
                       ,.count_o(ctr_lo  [j][k][i])
                       );
               end

             // * wire counter to input; this is always ready to send
             assign data [j][0][i]    = ctr_lo[j][0][i];
             assign valid[j][0][i]    = 1'b1;
             assign ctr_incr[j][0][i]  = yumi[j][0][i];

             // * wire paired counter to output; we receive at different
             // rates based on channel number.

             assign yumi[!j][1][i]     = valid[!j][1][i] & (~asymmetric_lp | (cycle[i:0]==0));
             assign ctr_incr[!j][1][i] = yumi[!j][1][i];

             // check data on receiving end of channel
             always_ff @(negedge clk)
               assert(reset | ~valid[!j][1][i]
                      | (data[!j][1][i] == ctr_lo[!j][1][i][width_lp-1:0]))
                 else $error("%m mismatch (data=%x) (counter=%x)"
                             ,data   [!j][1][i]
                             ,ctr_lo [!j][1][i][width_lp-1:0] // need to shorten value to compare to
                             );
          end // block: rof3
     end // block: rof2

   // termination condition: all counters reach final value?

endmodule
