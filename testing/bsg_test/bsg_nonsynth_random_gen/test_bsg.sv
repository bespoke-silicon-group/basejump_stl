`define WIDTH_P 3
`define SEED_P  10

/**************************** TEST RATIONALE *******************************

1. STATE SPACE

  In the first half of the test, the yumi signal is continuously asserted
  generating a random number every cycle. After that, yumi signal is
  complimented every 5 clock cycles, thus exercising the other half of the
  state space. The generated random numbers are logged to output.log.

2. PARAMETERIZATION

  Width of the output data and the seed, the random number generator in DUT
  is instantiated with are provided as parameters.

***************************************************************************/

module test_bsg;
  
  localparam cycle_time_lp  = 20;
  localparam width_lp       = `WIDTH_P; // width of test input
  localparam seed_lp        = `SEED_P;  // seed for random function
  localparam count_width_lp = 8;        // width of the cycle counter;
                                        // test runs for (2^count_width_lp) cycles 

  wire clk;
  wire reset;
  logic [count_width_lp-1:0] count;
  
  bsg_nonsynth_clock_gen #(  .cycle_time_p(cycle_time_lp)
                          )  clock_gen
                          (  .o(clk)
                          );
    
  bsg_nonsynth_reset_gen #(  .num_clocks_p     (1)
                           , .reset_cycles_lo_p(5)
                           , .reset_cycles_hi_p(5)
                          )  reset_gen
                          (  .clk_i        (clk) 
                           , .async_reset_o(reset)
                          );

  bsg_cycle_counter #(  .width_p(count_width_lp)
                     )  cycle_counter
                     (  .clk_i    (clk)
                      , .reset_i(reset)
                      , .ctr_r_o(count)
                     );

  initial
  begin
    $display("\n\n\n");
    $display(  "==========================================================\n"
             , "Width: %d\n", width_lp
             , "Seed : %d\n", seed_lp
            );
  end

  
  logic test_input_yumi, test_input_yumi_r; // yumi_i
  logic [width_lp-1:0] test_output, test_output_r; // data_o
  logic finish_r;

  // test stimulus generation
  always_ff@(posedge clk)
  begin
    if(reset)
      begin
        test_input_yumi <= 1'b0;
        finish_r   <= 1'b0;
      end
    else
      if(count < {1'b0, {(count_width_lp-1){1'b1}}}) // yumi is continuously asserted
        test_input_yumi <= 1'b1;
      else if(count == {1'b1, {(count_width_lp-1){1'b0}}}) // yumi is low after half time
        test_input_yumi <= 1'b0;
      else
        test_input_yumi <= #(4*cycle_time_lp) ~test_input_yumi; // yumi is complimented every 5 clk cycles
    
    if(&count)
      finish_r <= 1'b1;
    if(finish_r)
      begin
        $display("===============================================================\n");
        $finish;
      end
  end

  // test output validation
  always_ff @(posedge clk)
  begin
    test_input_yumi_r  <= test_input_yumi;
    test_output_r <= test_output;
    
    /*$display("yumi: %b, test_output: %b\n"
             , test_input_yumi, test_output);*/

    if(test_input_yumi_r == 1'b0)
      assert(test_output == test_output_r)
        else $error("previous value is not retained when yumi is not asserted\n");
  end

  bsg_nonsynth_random_gen #(  .width_p(width_lp)
                            , .seed_p (seed_lp)
                           )  DUT
                           (  .clk_i  (clk)
                            , .reset_i(reset)
                            , .yumi_i (test_input_yumi)
                            , .data_o (test_output)
                           );

  
  // generated test output (random numbers) are logged to output.log 
  bsg_nonsynth_ascii_writer #(  .width_p      (width_lp)
                              , .values_p     (1)
                              , .filename_p   ("output.log")
                              , .fopen_param_p("a+")
                              , .format_p     ("%b")
                             )  ascii_writer
                             (  .clk    (clk)
                              , .reset_i(reset)
                              , .valid_i(test_input_yumi)
                              , .data_i (test_output)
                             );

endmodule
