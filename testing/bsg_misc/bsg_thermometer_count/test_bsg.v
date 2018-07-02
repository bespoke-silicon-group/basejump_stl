`define WIDTH_P 2

/**************************** TEST RATIONALE *******************************

1. STATE SPACE

  Number of possible values for a thermometer code input of WIDTH_P is 
  WIDTH_P+1. Hence it is feasible to exhaustively test the DUT. This test 
  module generates thermometer codes as input to the DUT starting with 
  00...0. After every cycle this input is multiplied by 2 and incremented 
  by 1 and thus generating a sequence of thermometer codes. Since after 
  every cycle the value of the thermometer code increases by 1, a counter 
  can be initiated and it's count value can be used to validate the 
  correctness of the output of the DUT. 

2. PARAMETERIZATION

  The parameter WIDTH_P determines the behavior of the function in a 
  significant way, because each of WIDTH_P = 1, 2, 3, 4 and WIDTH_P>4 are 
  handled differently. So a minimal set of tests might be WIDTH_P=1,2,3,4,5. 
  However, since there are relatively few cases for each WIDTH_P, an 
  alternative approach is to test WIDTH_P=1..512, which gives us brute 
  force assurance.

***************************************************************************/
module test_bsg;
  
  // clock and reset generation
  localparam cycle_time_lp = 20;
  localparam width_lp      = `WIDTH_P; // width of test input
  
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
  
  logic [width_lp-1:0] test_input; // input therm code
  wire  [$clog2(width_lp+1)-1:0] test_output; // value of input therm code 
                                              // (output of DUT)
  
  logic [$clog2(width_lp+1):0]   count;     // number of clock cycles after reset
  logic finish_r;
  
  bsg_cycle_counter #(  .width_p($clog2(width_lp+1)+1)
                     )  bcc
                     (  .clk_i    (clk)
                      , .reset_i(reset)
                      , .ctr_r_o(count)
                     );
  
  // no. of set bits in input therm code
  // increases by one after every clock cycle
  // cycle 1: test_input = 000, count =  1
  // cycle 2: (000) << 1 + 1 = 001, 2 
  // cycle 3: (001) << 1 + 1 = 011, 3
  // cycle 3: (011) << 1 + 1 = 111, 4
  assign test_input = width_lp'((1 << count) - 1);
  
  always_ff @(posedge clk)
    begin
      if(reset)
        finish_r <= 1'b0;
      else 
        begin
          if(&test_input) // finish with 11..1
            finish_r <= 1'b1;
          if(finish_r)
            begin
              $display("========================================================\n");
              $finish;
            end
        end
    end
    
  always_ff @(posedge clk)
  begin
    /*$display("test_input: %b, count: %b, test_output: %b"
             , test_input, count, test_output);*/
    if(!reset)
      assert(count == test_output)
          else $error("mismatch on input %x;, expected output: %x;, test_output: %x"
                        , test_input, count, test_output);
  end
  
  bsg_thermometer_count #(  .width_p(width_lp)
                         )  DUT
                         (  .i(test_input)
                          , .o(test_output)
                         );
                                             
endmodule
