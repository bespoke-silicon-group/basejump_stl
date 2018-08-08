`define WIDTH_P 4

/********************************** TEST RATIONALE *************************

1. STATE SPACE

  Since the values of the data inputs have little influence on functioning 
  of the bitwise mux, they are fixed to be 11...1 & 00...0 and not varied. 
  Hence for each bit, output equals its corresponding select value. The 
  select input is varied to cover all the bit combinations.

2. PARAMETERIZATION

  Since the UUT implements same algorithm for all widths, an arbitrary set 
  of tests that include edge cases would suffice. So the minimum set of tests 
  might be WIDTH_P=1,2,3,4.

***************************************************************************/

module test_bsg;
  
  // clock and reset generation
  localparam cycle_time_lp = 20;
  localparam width_lp = `WIDTH_P; // width of test input
  
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
    $display("WIDTH_P: %d\n", width_lp);
  end 
                                        
  logic [width_lp-1:0] test_input_A, 
                       test_input_B, 
                       test_input_sel, 
                       test_output, 
                       test_input_sel_r;
                       
  always_ff @(posedge clk)
  begin
    if(reset)
      begin
        test_input_A <= {width_lp{1'b1}};
        test_input_B <= 0;
        test_input_sel <= 0;
      end
    else
      test_input_sel <= test_input_sel+1;
    
    test_input_sel_r <= test_input_sel;
  end
  
  always_ff @(posedge clk)
  begin
    if(!reset)  
      assert (test_output==test_input_sel)
        else $error("mismatch on input %x", test_input_sel);
    
    /*$display("\ntest_input_A: %b test_input_B: %b test_input_sel: %b test_output: %b"
             , test_input_A, test_input_B, test_input_sel, test_output);*/
    
    if((&test_input_sel_r) & (~|test_input_sel))
      begin
        $display("==============================================================\n");
        $finish;
      end
  end
  
  bsg_mux_bitwise #(
    .width_p(width_lp)
  )  DUT (
    .data0_i(test_input_A)
    ,.data1_i(test_input_B)
    ,.sel_i(test_input_sel)
    ,.data_o(test_output)
  );
                                  
  
endmodule
