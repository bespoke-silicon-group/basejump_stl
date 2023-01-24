/**************************** TEST RATIONALE *******************************

1. STATE SPACE

  The two parts of the input test_input[0] and test_input[1] are initiated
  with 00..0 and 11..1 respectively. Every cycle test_input[0] is incremented 
  while decrementing test_input[1] thus covering the entire state space.

2. PARAMETERIZATION

  The behaviour of the design is not much influenced by WIDTH_P. It is better
  to exhaustively test different conditions by varying T_P and BITS_P though.
  And clearly we need to test with both values of cond_swap_on_equal_p. So a
  minimum set tests might be WIDTH_P=1,3 T_P=0,1,2 BITS_P=1,2,3 and
  COND_SWAP_ON_EQUAL_P=0,1. We need not worry about the incompatible combinations
  in this set because such tests finish leaving a message without any errors.
  
***************************************************************************/

module test_bsg
#(
  parameter width_p              = `WIDTH_P,
  parameter t_p                  = `T_P,
  parameter b_p                  = (`T_P - `BITS_P + 1),
  parameter cond_swap_on_equal_p = `COND_SWAP_ON_EQUAL_P,
  parameter cycle_time_p = 20,
  parameter reset_cycles_lo_p=1,
  parameter reset_cycles_hi_p=5
);

  wire clk;
  wire reset;
  
  bsg_nonsynth_clock_gen
    #(.cycle_time_p(cycle_time_p))
    clock_gen (.o(clk));
  
  bsg_nonsynth_reset_gen
    #(.num_clocks_p     (1)
     ,.reset_cycles_lo_p(reset_cycles_lo_p)
     ,.reset_cycles_hi_p(reset_cycles_hi_p)
     )
    reset_gen
     (.clk_i        (clk)
     ,.async_reset_o(reset)
     );

  initial
  begin
    $display(  "\n\n\n"
             , "=========================================================\n"
             , "testing bsg_comapre_and_swap with ...\n"
             , " WIDTH_P             :%d\n", width_p
             , " T_P                 :%d\n", t_p
             , " B_P                 :%d\n", b_p
             , " COND_SWAP_ON_EQUAL_P:%d\n", cond_swap_on_equal_p
            );
    
    // finish if params are not compatible 
    assert((t_p <= width_p-1) & (0 <= b_p) & (b_p <= t_p))
      else 
        begin
          $display("Incompatible params: %d, %d, %d, %d,\n" 
  		            , width_p, t_p, b_p, cond_swap_on_equal_p);
          $finish;
        end
  end

  logic [1:0] [width_p-1:0] test_input, test_output;
  logic test_input_swap, test_output_swapped, finish_r;
  
  always_ff @(posedge clk)
  begin
    if(reset)
      begin
        test_input[0]   <= width_p ' (0);    // initiate with 00..0
        test_input[1]   <= {width_p {1'b1}}; // initiate with 11..1
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
    assert(reset || (test_output_swapped == ((test_input[0][t_p:b_p] > test_input[1][t_p:b_p])
                                    | ((cond_swap_on_equal_p & test_input_swap)
                                      & (test_input[0] == test_input[1])
                                      )
                                  ))
          )
      else $error("swapped_o: mismatch on input %x", test_input);

    assert(reset || (test_output == ((test_input[0][t_p:b_p] > test_input[1][t_p:b_p])
                            | ((cond_swap_on_equal_p & test_input_swap)
                              & (test_input[0] == test_input[1])
                              )
                          )
                          ? {test_input[0], test_input[1]}
                          : test_input)
          )
      else $error("data_o: mismatch on input %x", test_input);
  end

 // generate DUT only if params are compatible
 if((t_p <= width_p-1) & (0 <= b_p) & (b_p <= t_p)) 
    bsg_compare_and_swap #(  .width_p             (width_p)
                           , .t_p                 (t_p)
                           , .b_p                 (b_p)
                           , .cond_swap_on_equal_p(cond_swap_on_equal_p)
                          )  DUT
                          (  .data_i         (test_input)
                           , .swap_on_equal_i(test_input_swap)
                           , .data_o         (test_output)
                           , .swapped_o      (test_output_swapped)
                          );
  
   
endmodule
