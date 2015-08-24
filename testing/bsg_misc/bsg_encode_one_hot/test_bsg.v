`define WIDTH_P 2

/**************************** TEST RATIONALE *******************************

1. STATE SPACE

  The output of the function is undefined if there is more than a single 1 
  bit set in the function, so that fortunately limits the state space that 
  needs to be tested, and means that we can exhaustively test the function, 
  simply by testing the following inputs: all zeros, and the value 1 
  shifted from 0 to WIDTH_P bits. Clearly, we should test both outputs 
  values.

2. PARAMETERIZATION

  The parameter WIDTH_P determines the behavior of the function in a 
  significant way, because it is written as a divide-and-conquer recursive 
  algorithm. Significantly, in the cost, the case (WIDTH_P=1) is a special 
  case, and power of two widths and non-power of two-widths are handled with 
  different clauses.  So a minimal set of tests might be WIDTH_P=1, 
  WIDTH_P=4, and WIDTH_P=5,6,7. However, since there are relatively few 
  cases, an alternative approach is to test WIDTH_P=1..512, 
  which gives us brute force assurance.

***************************************************************************/

module test_bsg;
  
  localparam cycle_time_lp = 20;
  
  wire clk;
  wire reset;
  localparam width_lp = `WIDTH_P;

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
    $display("WIDTH_P: %d\n", width_lp);
  end
                                      
  logic [width_lp-1:0] test_input_n, test_input, test_input_r;
  logic [`BSG_SAFE_CLOG2(width_lp)-1:0] count_n, count, test_output_addr; 
                                                            //encoded addr 
  logic v, v_n, test_output_v; // valid bits
  
  always_ff @(posedge clk)
  begin
    if(reset)
      begin
        test_input_n <= {{(width_lp-1){1'b0}}, 1'b1}; // initial value is 00..01
        count_n      <= 0; // encoded value (binary value) in a counter
        v_n          <= 1'b1;
      end 
    else
      begin
        test_input_n <= (test_input_n << 1); // shifts 1 to left by one 
                                             // bit and final value is 00...00
        if(test_input_n[width_lp-1])
          begin
            count_n <= 0; // count brought back to 0
            v_n <= 1'b0;  // when test_input is 00...00
          end
        else
          count_n <= count_n+1;
        
        if((~|test_input) & (!test_input_r[width_lp-1]))
          begin
            $display("===========================================================\n");
            $finish;
          end
        
        if(width_lp != 1)
          assert((test_output_addr == count) & (v == test_output_v))
            else $error("mismatch on input %x", test_input);
      end
    
    test_input   <= test_input_n;
    test_input_r <= test_input;
    count        <= count_n;
    v            <= v_n;
    
    /*$display("\ntest_input: %b, count: %b, test_output: %b"
             , test_input, count, test_output_addr);*/

  end
  
  bsg_encode_one_hot #(  .width_p(width_lp)
                      )  DUT
                      (  .i     (test_input)
                       , .addr_o(test_output_addr)
                       , .v_o   (test_output_v)
                      );
  
  /*// log test results
  logic [width_lp-1:0] norm_test_output, norm_count;
  
  assign norm_test_output = {{(width_lp-($clog2(width_lp))-1){1'b0}}, 
                            test_output_addr, test_output_v};
  assign norm_count = {{(width_lp-($clog2(width_lp))-1){1'b0}}, count, v};
  
  bsg_nonsynth_ascii_writer #(  .width_p      (width_lp)
                              , .values_p     (3)
                              , .filename_p   ("output.log")
                              , .fopen_param_p("a+")
                              , .format_p     ("%b")
                             )  ascii_writer
                             (  .clk    (clk)
                              , .reset_i(reset)
                              , .valid_i(1'b1)
                              , .data_i ({norm_test_output,
                                           norm_count,
                                           test_input}
                                         )
                             );*/
  
endmodule
