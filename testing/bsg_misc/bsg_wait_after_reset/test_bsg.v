`define WIDTH_P 3

/**************************** TEST RATIONALE *******************************

1. STATE SPACE

  WIDTH_P is the width of the number of wait cycles needed. So each test
  monitors the output for 2**WIDTH_P cycles.   

2. PARAMETERIZATION

  The parameter WIDTH_P has little influence on the way DUT synthesizes. So
  a minimum set of tests might be WIDTH_P = 1,2,3,4. Tests with large 
  WIDTH_P may take long to finish because the number of cycles the test runs
  grows exponentially with it.

***************************************************************************/

module test_bsg;
  
  localparam lg_wait_cycles_lp = `WIDTH_P; // width of the timer
  localparam cycle_time_lp     = 20;
  
  wire clk;
  wire reset;
  
  bsg_nonsynth_clock_gen #(  .cycle_time_p(cycle_time_lp)
                          )  clock_gen
                          (  .o(clk)
                          );
    
  bsg_nonsynth_reset_gen #(  .num_clocks_p     (1)
                           , .reset_cycles_lo_p(1)
                           , .reset_cycles_hi_p(5)
                          )  reset_gen
                          (  .clk_i        (clk)
                           , .async_reset_o(reset)
                          );
                          
  initial
  begin
    $display("\n\n\n");
    $display("===========================================================");
    $display("testing with ...");
    $display("WIDTH_P: %d\n", `WIDTH_P);
  end 
  
  logic test_output, test_output_r, ref_test_output;
  time reset_time, ready_time;
  
  assign ref_test_output = ((ready_time-reset_time)/cycle_time_lp)
                                 == (2**`WIDTH_P); // checks correctness
                                                   // of ready timing
  
  always_ff @(negedge reset)
  begin
    reset_time <= $time - (cycle_time_lp / 2); // the test reset becomes 0 
                                               // on negedge
    ready_time <= 0;
  end
  
  always_ff @(posedge test_output)
    ready_time <= $time;
  
  always_ff @(posedge clk)
  begin
    test_output_r <= test_output;
    
    /*$display("\ntest_output: %b @ time: %d", test_output, $time);*/ 

    if(!reset)  
      assert (test_output == ref_test_output)
        else $error("mismatch at time = %d", $time); 
    
    if(test_output_r)
      begin
        $display("=============================================================\n");
        $finish;
      end
  end
  
  bsg_wait_after_reset #(  .lg_wait_cycles_p(lg_wait_cycles_lp)
                        )  DUT
                        (  .clk_i    (clk)
                         , .reset_i  (reset)
                         , .ready_r_o(test_output)
                        );
  
  /*//log test results
  logic [(3*lg_wait_cycles_lp)-1:0] log;
  
  assign log = {  `BSG_SAFE_CLOG2(lg_wait_cycles_lp+1)'(test_output)
                , `BSG_SAFE_CLOG2(lg_wait_cycles_lp+1)'(ref_test_output)
                , `BSG_SAFE_CLOG2(lg_wait_cycles_lp+1)'(lg_wait_cycles_lp)};
  
  bsg_nonsynth_ascii_writer #(  .width_p      (`BSG_SAFE_CLOG2(
                                                    lg_wait_cycles_lp+1))
                              , .values_p     (3)
                              , .filename_p   ("output.log")
                              , .fopen_param_p("a+")
                              , .format_p     ("%x")
                             )  ascii_writer
                             (  .clk    (clk)
                              , .reset_i(reset)
                              , .valid_i(1'b1)
                              , .data_i (log)
                             );*/
  
endmodule
