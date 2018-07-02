`define WIDTH_P 3
`define CASE_P  1 // XOR:1, AND:2, OR:3

/**************************** TEST RATIONALE *******************************

1. STATE SPACE

  This module tests hi_to_lo and lo_to_hi simultaneously by instantiating
  two DUTs, DUT_hilo and DUT_lohi. Each unit is tested for entire state
  space of a binary number of WIDTH_P.

2. PARAMETERIZATION

  DUT's implementation is not much influenced by WIDTH_P. CASE_P can have
  only one of the three values 100, 010 and 001. So a minimum set of test
  might be WIDTH_P = 1,2,3,4 and CASE_P = 100,010,001. Tests with a large
  WIDTH_P take long to finish because the number of test inputs grow
  exponentially with WIDTH_P.

***************************************************************************/

module test_bsg;

  localparam cycle_time_lp = 20;
  localparam width_lp      = `WIDTH_P; // width of test input
  localparam xor_lp        = (`CASE_P==1);
  localparam and_lp        = (`CASE_P==2);
  localparam or_lp         = (`CASE_P==3);

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
    $display("WIDTH_P: %d", `WIDTH_P);
    $display("CASE_P : %d\n", `CASE_P);
  end

  logic [width_lp-1:0] test_input, test_output_hilo, test_output_lohi;
  logic [width_lp-1:0] ref_test_output_hilo, ref_test_output_lohi;
  logic finish_r;

  always_comb
  begin
    // hi to lo
    if(xor_lp == 1)
      begin
        ref_test_output_hilo[width_lp-1] = 0 ^ test_input[width_lp-1];
        for(int i=width_lp-2; i>=0; --i)
          ref_test_output_hilo[i] = ref_test_output_hilo[i+1] ^ test_input[i];
      end
    else if(and_lp == 1)
      begin
        ref_test_output_hilo[width_lp-1] = 1 & test_input[width_lp-1];
        for(int i=width_lp-2; i>=0; --i)
          ref_test_output_hilo[i] = ref_test_output_hilo[i+1] & test_input[i];
      end
    else if(or_lp == 1)
      begin
        ref_test_output_hilo[width_lp-1] = 0 | test_input[width_lp-1];
        for(int i=width_lp-2; i>=0; --i)
          ref_test_output_hilo[i] = ref_test_output_hilo[i+1] | test_input[i];
      end

    // lo to hi
    if(xor_lp == 1)
      begin
        ref_test_output_lohi[0] = 0 ^ test_input[0];
        for(int i=1; i<width_lp; ++i)
          ref_test_output_lohi[i] = ref_test_output_lohi[i-1] ^ test_input[i];
      end
    else if(and_lp == 1)
      begin
        ref_test_output_lohi[0] = 1 & test_input[0];
        for(int i=1; i<width_lp; ++i)
          ref_test_output_lohi[i] = ref_test_output_lohi[i-1] & test_input[i];
      end
    else if(or_lp == 1)
      begin
        ref_test_output_lohi[0] = 0 | test_input[0];
        for(int i=1; i<width_lp; ++i)
          ref_test_output_lohi[i] = ref_test_output_lohi[i-1] | test_input[i];
      end
  end

  always_ff @(posedge clk)
  begin
    if(reset)
      begin
        test_input <= 0;
        finish_r   <= 1'b0;
      end
    else
      test_input <= test_input+1;

    if(&test_input)
      finish_r <= 1'b1;
  end

  always_ff @(posedge clk)
  begin
    /*$display("test_input: %b, test_output_hilo: %b, test_output_lohi: %b"
             , test_input, test_output_hilo, test_output_lohi);*/
    if(!reset)
      begin
        assert (ref_test_output_hilo == test_output_hilo)
          else $error("hi_to_lo_scan: mismatch on input %x; expected output: %x; "
                      , test_input, ref_test_output_hilo, "test output: %x", test_output_hilo);

        assert (ref_test_output_lohi == test_output_lohi)
          else $error("lo_to_hi_scan: mismatch on input %x; expected output: %x; "
                      , test_input, ref_test_output_lohi, "test output: %x", test_output_lohi);
      end

    if(finish_r)
      begin
        $display("==============================================================\n");
        $finish;
      end
  end

  bsg_scan #(  .width_p   (width_lp)
             , .xor_p     (xor_lp)
             , .and_p     (and_lp)
             , .or_p      (or_lp)
             , .lo_to_hi_p(0)
            )  DUT_hilo
            (  .i(test_input)
             , .o(test_output_hilo)
            );

  bsg_scan #(  .width_p   (width_lp)
             , .xor_p     (xor_lp)
             , .and_p     (and_lp)
             , .or_p      (or_lp)
             , .lo_to_hi_p(1)
            )  DUT_lohi
            (  .i(test_input)
             , .o(test_output_lohi)
            );

  /*logic [(5*width_lp)-1:0] log;
  assign log = {test_output_lohi, test_output_hilo, ref_test_output_lohi
                  , ref_test_output_hilo, test_input};
  bsg_nonsynth_ascii_writer #(  .width_p      (width_lp)
                              , .values_p     (5)
                              , .filename_p   ("output.log")
                              , .fopen_param_p("a+")
                              , .format_p     ("%b")
                             )  ascii_writer(  .clk    (clk)
                                             , .reset_i(reset)
                                             , .valid_i(1'b1)
                                             , .data_i (log)
                                            );*/
endmodule
