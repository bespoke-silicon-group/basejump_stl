`define WIDTH_P 2

/**************************** TEST RATIONALE *******************************
1. STATE SPACE
  An internal counter keeps track of the count which is compared with the 
  output of the DUT. This test continues for 2**WIDTH_P cycles and hence 
  tests the DUT exhaustively.
2. PARAMETERIZATION
  A minimum set of tests might be WIDTH_P=1,2,..,8. Since the number of test
  cases grows exponentially, tests with large WIDTH_P takes very long to
  finish.
***************************************************************************/

module test_bsg
#(  
  parameter cycle_time_p = 20,
  parameter width_p = `WIDTH_P,
  parameter reset_cycles_lo_p=1,
  parameter reset_cycles_hi_p=5
);

  wire clk;
  wire reset;
  
  `ifdef VERILATOR
    bsg_nonsynth_dpi_clock_gen
  `else
    bsg_nonsynth_clock_gen
  `endif
   #(.cycle_time_p(cycle_time_p))
   clock_gen
    (.o(clk));
    
  bsg_nonsynth_reset_gen #(  .num_clocks_p     (1)
                           , .reset_cycles_lo_p(reset_cycles_lo_p)
                           , .reset_cycles_hi_p(reset_cycles_lo_p)
                          )  reset_gen
                          (  .clk_i        (clk)
                           , .async_reset_o(reset)
                          );

  initial
  begin
    $display("\n\n\n");
    $display(  "=============================================================\n"
             , "testing with ...\n"
             , "WIDTH_P: %d\n", width_p
            );
  end
                                        
  logic [width_p-1:0] count, count_r;
  wire  [width_p-1:0] test_output;
  
  always_ff @(posedge clk)
  begin
    if(reset)
      count <= 0;
    else
      count <= count + 1;
    
    //$display("count: %d, test_output: %d\n", count, test_output);///////////
    count_r <= count;
  end

  always_ff @(posedge clk)
  begin
    if(!reset)
      if(count != test_output)
        $error("mismatch on clock cycle %x", count);
    
    if(!(|count) & (&count_r)) // finish when count value returns to 0
      begin
        $display("=============================================================\n");
        $finish;
      end
  end
  
  bsg_cycle_counter #(  .width_p(width_p)
                     )  DUT
                     (  .clk_i    (clk)
                      , .reset_i(reset)
                      , .ctr_r_o(test_output)
                     );
                             
  /*bsg_nonsynth_ascii_writer #(  .width_p      (width_p)
                              , .values_p     (2)
                              , .filename_p   ("output.log")
                              , .fopen_param_p("a+")
                              , .format_p     ("%x")
                             )  ascii_writer
                             (  .clk    (clk)
                              , .reset_i(reset)
                              , .valid_i(1'b1)
                              , .data_i ({test_output,
                                          count}
                                        )
                             );*/
endmodule