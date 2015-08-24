`define WIDTH_P 3

/**************************** TEST RATIONALE *******************************

1. STATE SPACE

  This module tests the DUT exhaustively with all the possible gray codes of
  WIDTH_P. 

2. PARAMETERIZATION

  The parameter WIDTH_P determines the behavior of the function in a 
  significant way, because it is written as a divide-and-conquer recursive 
  algorithm. WIDTH_P<3, WIDTH_P=4 and WIDTH_P>4 are handled with different
  clauses. So a minimum set of tests might be WIDTH_P = 1,2,3,4,5,6,7. Since
  the number of test cases grows exponentially with WIDTH_P, large WIDTH_P
  take a very long time to finish.

***************************************************************************/

module test_bsg;

  localparam width_lp      = `WIDTH_P;
  localparam cycle_time_lp = 20;
  
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
                          
  logic [width_lp-1:0]           test_input, test_input_n;
  logic [width_lp-1:0]           count;
  logic [$clog2(width_lp+1)-1:0] test_output, popcount; //popcount is expected output
  logic finish_r;  
  
  // Gray codes are used as test inputs since pop code of gray code of every 
  // next number is incremented/decremented only once.  
  if(width_lp > 1)
    bsg_binary_plus_one_to_gray #(  .width_p(width_lp)
                                 )  binary_pone_gray
                                 (  .binary_i(width_lp'(count-1))
                                  , .gray_o  (test_input_n)
                                 );
  else
    assign test_input_n = count;
  
  always_ff @(posedge clk)
  begin
    test_input   <= test_input_n;
    
    if(reset)
      begin
        count    <= 0;
        popcount <= 0;
      end
    else
      begin
        count <= count + 1;
        if(test_input_n > test_input)
          popcount <= popcount + 1;
        else if(test_input_n < test_input)
          popcount <= popcount - 1;
      end
  end

  always_ff @(posedge clk)
  begin
    /*$display("\ncount: %b, test_input: %b, test_output: %b"
             , count, test_input, test_output);*/

    if(!reset)  
      assert(test_output == popcount)
        else $error("mismatch on input %b, expected output: %b, test_output:%b"
                    , test_input, popcount, test_output);
    
    if(&count)
      finish_r <= 1'b1;
    if(finish_r)
      begin
        $display("=============================================================\n");
        $finish;
      end
  end 
  
  bsg_popcount #(  .width_p(width_lp)
                )  DUT
                (  .i(test_input)
                 , .o(test_output)
                );
                
  /*logic [(3*width_lp)-1:0] log;
  assign log = {  width_lp'(test_output)
                , width_lp'(popcount)
                , test_input};
  bsg_nonsynth_ascii_writer #(  .width_p      (width_lp)
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
