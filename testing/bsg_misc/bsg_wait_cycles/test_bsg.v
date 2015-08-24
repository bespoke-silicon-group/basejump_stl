`define CYCLES_P 3
`define WAIT_AFTER_RESET_P 1 // lg of number of cycles; after reset 
                             // and before activate
                             
/**************************** TEST RATIONALE *******************************

1. STATE SPACE

  The timing of 'activate' and the number of wait cycles are determined by
  the two parameters, WAIT_AFTER_RESET_P and CYCLES_P respectively. 

2. PARAMETERIZATION

  The implementation of DUT is independent of the parameter values. So a
  minimum set of tests might be CYCLES_P = 0,1,2,3 and WAIT_AFTER_RESET_P = 
  0,1,2,3. Since each test runs for relatively a few clock cycles, an
  alternate approach would be to test for CYCLES_P = 0...32 and
  WAIT_AFTER_RESET_P = 0...32.

***************************************************************************/

module test_bsg;
  
  localparam cycle_time_lp = 20;
  localparam cycles_lp     = `CYCLES_P;
  
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
    $display("CYCLES_P         : %d", cycles_lp);
    $display("WAIT_AFTER_REST_P: %d\n", `WAIT_AFTER_RESET_P);
  end 
  
  logic test_input_activate, test_output, ref_test_output; 
  logic activate, finish; // activate is 1 after WAIT_AFTER_RESET_P cycles
                          // after reset
  time  active_time; // time at the falling edge of test_input_activate (activate_i) of DUT
      
  bsg_wait_after_reset #(  .lg_wait_cycles_p(`WAIT_AFTER_RESET_P)
                        )  wait_after_reset
                        (  .reset_i  (reset)
                         , .clk_i    (clk)
                         , .ready_r_o(activate)
                        );
    
  always_ff @(posedge activate)
  begin  
    active_time <= ($time + cycle_time_lp); // test_input_activate is ON for 1 clock cycle
                                            // after posedge of activate
    test_input_activate  <= 1'b1;
  end
  
  always_ff @(posedge clk)
  begin   
    if(reset)
      begin
        finish      <= 1'b0;
        active_time <= 0;
        test_input_activate  <= 1'b0;
        ref_test_output <= 1'b1;
      end  
    else
      begin
        if(test_input_activate)
          test_input_activate <= 1'b0;
        
        if(activate)
          ref_test_output <= ($time >= (active_time + cycles_lp*cycle_time_lp));
        else if (active_time == 0)
          ref_test_output <= 1'b1; // bsg_wait_cycles 's output is initially high
                                   // until activate_i becomes high

        if((activate) & (!test_input_activate) & (test_output))
          finish <= 1'b1;
        if(finish)
          begin
            $display("===========================================================\n");
            $finish;
          end
      end
  end
  
  always_ff @(posedge clk)
  begin
    /*$display("ref_test_output: %b, test_output: %b"
               , ref_test_output, test_output);*/

    if(!reset)  
      assert(ref_test_output == test_output)
        else $error("mismatch at time %d", $time);
  end

  bsg_wait_cycles #(  .cycles_p(cycles_lp)
                   )  DUT
                   (  .clk_i     (clk)
                    , .reset_i   (reset)
                    , .activate_i(test_input_activate)
                    , .ready_r_o (test_output)
                   );
                   
  
  /*// log the results
  logic [2:0] log;
  
  assign log = { (test_output)
                ,(ref_test_output)
                ,(test_input_activate)};
  
  bsg_nonsynth_ascii_writer #(  .width_p      (1)
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
