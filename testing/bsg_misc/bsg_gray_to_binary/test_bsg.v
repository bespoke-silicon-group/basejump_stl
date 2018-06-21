`define WIDTH_P 2

/**************************** TEST RATIONALE *******************************

1. STATE SPACE

  This module generates gray codes of every possible binary number of WIDTH_P
  and feeds these vales as test inputs to the DUT. An up-counter is used to 
  generate the binary numbers whose gray codes are test inputs to DUT. The 
  output of the DUT is compared with count to check correctness. Thus the DUT 
  is tested exhaustively for any given WIDTH_P.

2. PARAMETERIZATION

  The DUT uses a module already defined in bsg_misc to calculate the 
  value of the input gray code. Hence tests with WIDTH_P = 1,2,..8 would give 
  sufficient confidence. Since the number of test cases grows exponentially 
  with WIDTH_P, simulations with WIDTH_P > 16 would take very long time to 
  complete apart from generating a large "output.log".

***************************************************************************/
module test_bsg;
  
  localparam cycle_time_lp = 20;
  localparam width_lp = `WIDTH_P;
  
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
                                        
  logic [width_lp-1:0] count, count_r;
  bsg_cycle_counter #(  .width_p(width_lp)
                     )  bcc
                     (  .clk_i    (clk)
                      , .reset_i(reset)
                      , .ctr_r_o(count)
                     );
                             
  logic [width_lp-1:0] test_input;
  wire  [width_lp-1:0] test_output;
  assign test_input = (count>>1) ^ count; // test_input is gray code of count 
  
  always_ff @(posedge clk)
  begin
    count_r <= count;
    
    /*$display("\ntest_input: %b, count: %b, test_output: %b"
             , test_input, count, test_output);*/
    
    if(!reset)  
      assert(test_output == count)
        else $error("mismatch on input %x", test_input);
    
    if(!(|count) & (&count_r)) 
      begin
        $display("===============================================================\n");
        $finish;
      end
  end
  
  bsg_gray_to_binary #(  .width_p(width_lp)
                      )  DUT
                      (  .gray_i  (test_input)
                       , .binary_o(test_output)
                      );
                                     
  /*bsg_nonsynth_ascii_writer #(  .width_p      (width_lp)
                              , .values_p     (3)
                              , .filename_p   ("output.log")
                              , .fopen_param_p("a+")
                              , .format_p     ("%x")
                             )  ascii_writer
                             (  .clk    (clk)
                              , .reset_i(reset)
                              , .valid_i(1'b1)
                              , .data_i ({test_output,
                                          count,
                                          test_input}
                                        )
                             );*/
endmodule
