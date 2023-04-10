`define WIDTH_IN_P   3
`define WIDTH_OUT_P  2
`define LSB_TO_MSB_P 0

/********************************** TEST RATIONALE *************************

1. STATE SPACE

  Since the DUT doesn't calculate the output but only routes the input, the
  value of input has a little part to play in the functioning of DUT. So
  thermometer codes of WIDTH_IN_P are used as test inputs to reduce the time
  of each test significantly.

2. PARAMETERIZATION

  Widths of input and output are parameters in this test module. The cases
  WIDTH_IN_P > WIDTH_OUT_P and WIDTH_IN_P < WIDTH_OUT are handled
  differently in the DUT. So a minimum set of tests might be WIDTH_IN_P = 1,
  2,3,4,8 and WIDTH_OUT_P = 1,2,3,4,8.

***************************************************************************/

module test_bsg
#(
  parameter width_in_p   = `WIDTH_IN_P,
  parameter width_out_p  = `WIDTH_OUT_P,
  parameter lsb_to_msb_p = `LSB_TO_MSB_P,
  parameter divisions_p  = ((width_in_p % width_out_p) == 0)
                             ? (width_in_p / width_out_p)
                             : (width_in_p / width_out_p) + 1,
  parameter cycle_time_p = 20,
  parameter reset_cycles_lo_p=1,
  parameter reset_cycles_hi_p=5
);

  wire clk;
  wire reset;

  bsg_nonsynth_clock_gen
    #(.cycle_time_p(cycle_time_p))
    clock_gen
      (.o(clk));
    
  bsg_nonsynth_reset_gen
    #(.num_clocks_p     (1)
     ,.reset_cycles_lo_p(reset_cycles_lo_p)
     ,.reset_cycles_hi_p(reset_cycles_hi_p)
     )
    reset_gen
     (.clk_i        (clk) 
     ,.async_reset_o(reset)
     );

  initial
  begin
    /*$monitor("\n@%0t ps: ", $time
              , "test_input_data: %b, test_input_deque: %b"
              , test_input_data, test_input_deque
              , ", test_output_data: %b, test_output_deque: %b"
              , test_output_data, test_output_deque);*/

    $display("\n\n\n");
    $display("===========================================================");
    $display("testing bsg_channel_narrow with ...");
    $display("WIDTH_IN_P :  %d", width_in_p);
    $display("WIDTH_OUT_P:  %d", width_out_p);
    $display("LSB_TO_MSB_P: %d\n", lsb_to_msb_p);
  end

  logic [width_in_p-1:0]  test_input_data;
  logic test_input_deque;

  // two uuts are instantiated; one with lsb_to_msb_p = 0 and the other with 1
  logic [width_out_p-1:0] test_output_data;
  logic test_output_deque;

  logic [$clog2(divisions_p)-1:0] count_r;
  logic finish_r;

  always_ff @(posedge clk)
  begin
    if(reset)
      begin
        test_input_data  <= width_in_p ' (0);
        test_input_deque <= 1'b1;
        count_r          <= 0;
        finish_r         <= 1'b0;
      end
    else
      begin
        count_r <= count_r + test_input_deque;

        if(count_r == divisions_p-1)
          begin
            test_input_data  <= (test_input_data << 1) + 1;
                                        // input thermometer code
            count_r          <= 0;
            test_input_deque <= (divisions_p == 1);
          end
        else
          if(~test_input_deque)
            test_input_deque <= 1'b1;

        if(&test_input_data & (count_r == divisions_p - 1))
          finish_r <= 1'b1;
        if(finish_r)
          begin
            $display("==========================================================\n");
            $finish;
          end
      end
  end

   // vivado bug
   initial assert(0) else $display ("zoop %b %b", 1'b1, 2 ' (1'b1));

   reg        temp;

  always_ff @(posedge clk)
  begin
    if(!reset)
      begin
         // this craziness is because of a vivado bug that has issues mixing
         // casting and asserts
         temp = (!lsb_to_msb_p || test_output_data ==
                 (width_out_p ' (test_input_data >> (width_out_p*count_r))));

         assert(temp)
           else $error("1 lsb_to_msb_data: mismatch on input=%x output=%x count_r=%x"
                       , test_input_data, test_output_data, count_r,
                       );

         temp = (lsb_to_msb_p || test_output_data ==
                 width_out_p ' (test_input_data >> (width_out_p*(divisions_p - count_r - 1))));

         assert(temp)
           else $error("2 msb_to_lsb_data: mismatch on input %x ", test_input_data
                       , "division %x", count_r);

         temp = (!lsb_to_msb_p || test_output_deque == (count_r == divisions_p-1));
         assert(temp)
           else $error("3 lsb_to_msb_deque: mismatch on input %x ", test_input_data
                       , "division %x", count_r);

         temp = (lsb_to_msb_p || test_output_deque == (count_r == divisions_p-1));
         assert(temp)
          else $error("4 msb_to_lsb_deque: mismatch on input %x ", test_input_data
                         , "division %x", count_r);
      end
  end


  bsg_channel_narrow #(  .width_in_p  (width_in_p)
                       , .width_out_p (width_out_p)
                       , .lsb_to_msb_p(lsb_to_msb_p)
                      )  DUT
                      (  .clk_i    (clk)
                       , .reset_i  (reset)
                       , .data_i (test_input_data)
                       , .deque_o(test_output_deque)
                       , .data_o (test_output_data)
                       , .deque_i(test_input_deque)
                      );

  /*// logging; logs only lsb_to_msb_data
  localparam log_width_p = (width_in_p > width_out_p)
                            ? (width_in_p)
                            : (width_out_p);
  logic [3*log_width_p-1:0] log;

  assign log = {  log_width_p ' (test_output_data)
                , log_width_p ' (
                    width_out_p'(test_input_data >> (width_out_p*count_r)))
                , log_width_p ' (test_input_data)
               };
  bsg_nonsynth_ascii_writer #(.width_p      (log_width_p),
                              .values_p     (3),
                              .filename_p   ("output.log"),
                              .fopen_param_p("a+"),
                              .format_p     ("w")
                             )  ascii_writer(.clk    (clk),
                                              .reset_i(reset),
                                              .valid_i(1'b1),
                                              .data_i (log)
                                             );*/

endmodule
