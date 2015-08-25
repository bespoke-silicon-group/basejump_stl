`define WIDTH_P              2
`define T_P                  1
`define BITS_P               1 // no. of bits included starting from T_P
`define COND_SWAP_ON_EQUAL_P 0

/**************************** TEST RATIONALE *******************************

1. STATE SPACE

  The two parts of the input test_input[0] and test_input[1] are initiated
  with 00..0 and 11..1 respectively. Every cycle test_input[0] is incremented 
  while decrementing test_input[1] thus covering the entire state space.

2. PARAMETERIZATION

  The behaviour of the design is not much influenced by WIDTH_P. It is better
  to exhaustively test different conditions by varying T_P and BITS_P though.
  And clearly we need to test with both values of cond_swap_on_equal_lp. So a
  minimum set tests might be WIDTH_P=1,3 T_P=0,1,2 BITS_P=1,2,3 and
  COND_SWAP_ON_EQUAL_P=0,1. We need not worry about the incompatible combinations
  in this set because such tests finish leaving a message without any errors.
  
***************************************************************************/

module test_bsg;

  //calculating parameters
  localparam width_lp              = `WIDTH_P;
  localparam t_lp                  = `T_P;
  localparam b_lp                  = (`T_P - `BITS_P + 1);
  localparam cond_swap_on_equal_lp = `COND_SWAP_ON_EQUAL_P;
  
  
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
    $display(  "\n\n\n"
             , "=========================================================\n"
             , "testing bsg_comapre_and_swap with ...\n"
             , " WIDTH_P             :%d\n", width_lp
             , " T_P                 :%d\n", t_lp
             , " B_P                 :%d\n", b_lp
             , " COND_SWAP_ON_EQUAL_P:%d\n", cond_swap_on_equal_lp
            );
    
    // finish if params are not compatible 
    assert((t_lp <= width_lp-1) & (0 <= b_lp) & (b_lp <= t_lp))
      else 
        begin
          $display("Incompatible params: %d, %d, %d, %d,\n" 
  		            , width_lp, t_lp, b_lp, cond_swap_on_equal_lp);
          $finish;
        end
    
  end
    
  logic [1:0] [width_lp-1:0] test_input, test_output;
  logic test_input_swap, test_output_swapped, finish_r;
  
  always_ff @(posedge clk)
  begin          
    if(reset)
      begin
        test_input[0]   <= width_lp ' (0);    // initiate with 00..0
        test_input[1]   <= {width_lp {1'b1}}; // initiate with 11..1
        test_input_swap <= 1'b0;
        finish_r        <= 1'b0;
      end
    else
      begin
        test_input[0]   <= test_input[0] + 1;
        test_input[1]   <= test_input[1] - 1;
        test_input_swap <= !test_input_swap;
        
        if((&test_input[0]) & (~|test_input[1]))
          finish_r <= 1'b1;

        if(finish_r)
          begin
            $display("=========================================================\n");
            $finish;
          end
      end
  end
  
  always_ff @(posedge clk)
  begin
    if(!reset)  
      begin
        assert(test_output_swapped == ((test_input[0][t_lp:b_lp] > test_input[1][t_lp:b_lp])
                                       | ((cond_swap_on_equal_lp & test_input_swap)
                                          & (test_input[0] == test_input[1])
                                         )
                                      )
              )
          else $error("swapped_o: mismatch on input %x", test_input);

        assert(test_output == ((test_input[0][t_lp:b_lp] > test_input[1][t_lp:b_lp])
                               | ((cond_swap_on_equal_lp & test_input_swap)
                                  & (test_input[0] == test_input[1])
                                 )
                              )
                              ? {test_input[0], test_input[1]}
                              : test_input
              )
          else $error("data_o: mismatch on input %x", test_input);
      end
  end

 // generate DUT only if params are compatible
 if((t_lp <= width_lp-1) & (0 <= b_lp) & (b_lp <= t_lp)) 
    bsg_compare_and_swap #(  .width_p             (width_lp)
                           , .t_p                 (t_lp)
                           , .b_p                 (b_lp)
                           , .cond_swap_on_equal_p(cond_swap_on_equal_lp)
                          )  DUT
                          (  .data_i         (test_input)
                           , .swap_on_equal_i(test_input_swap)
                           , .data_o         (test_output)
                           , .swapped_o      (test_output_swapped)
                          );
  
   
endmodule
