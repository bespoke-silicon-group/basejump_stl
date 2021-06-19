`define MAX_VAL_P  7
`define INIT_VAL_P 0
`define MAX_STEP_P 1

`include "bsg_defines.v"

/**************************** TEST RATIONALE *******************************
1. STATE SPACE
  This test module tests the outputs of DUT for a complete count-cycle
  i.e., from INIT_VAL_P to MAX_VAL_P and then from MAX_VAL_P to INIT_VAL_P.
  If the MAX_VAL_P is less than INIT_VAL_P, simulation finishes
  without doing anything.
2. PARAMETERIZATION
  Since the DUT implements an algorithm that simply increments or decrements
  the count, an arbitrary set of tests that include that include the edge
  cases would do the job. So a minimum set of tests might be MAX_VAL_P=1,2,
  3,4 with INIT_VAL_P=0,1,2,3. No need to worry about making parameters
  compatiable as those tests finish without instatiating DUT.
***************************************************************************/

module test_bsg
#(parameter cycle_time_p = 20,
  parameter max_val_p    = `MAX_VAL_P,
  parameter init_val_p   = `INIT_VAL_P,
  parameter max_step_p   = `MAX_STEP_P,
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

  logic test_input_up, test_input_down, finish_r;
  logic [`BSG_WIDTH(max_val_p)-1:0] test_output;
  logic [`BSG_SAFE_CLOG2(max_val_p):0] prev_count, count;

  initial
  begin
    if(max_val_p < init_val_p) // checks if params are compatible
      begin
        $error(  "  Incompatible parameters"
               , ": initial value greater than maximum value\n");
        $finish;
      end

    $display(  "\n\n\n"
             , "================================================================="
             , "\ntesting with ...",
             , "\nMAX_VAL_P  = %d", `MAX_VAL_P
             , "\nINIT_VAL_P = %d\n", `INIT_VAL_P
             , "\nMAX_STEP_P = %d\n", `MAX_STEP_P
            );
  end

  always_ff @(posedge clk)
  begin
    if(reset)
      begin
        finish_r <= 0;
        if(init_val_p < max_val_p)
          {test_input_up, test_input_down} <= 2'b10;
        else
          {test_input_up, test_input_down} <= 2'b01;
      end
    else
      begin
        if((count == max_val_p-1) & test_input_up) // prevents overflow
          {test_input_up, test_input_down} <= 2'b01;
        else if((count == 1) & test_input_down)     // prevents underflow
          {test_input_up, test_input_down} <= 2'b10;

        if(finish_r)
          begin
            $display("==============================================================\n");
            $finish;
          end
        if((prev_count == 1) & (~|count)) // finish when count == 0
          finish_r <= 1;
      end
  end

  always_ff @(posedge clk)
  begin
    if(reset)
      begin
        count      <= init_val_p;
        prev_count <= init_val_p;
      end
    else
      begin
        //$display("count: %d, test_output: %d @  time: %d\n", count, test_output, $time);
        if(count != test_output)
          $error("mismatch on time %d\n", $time);

        count      <= count + test_input_up - test_input_down;
        prev_count <= count;
      end
  end

  if(max_val_p >= init_val_p) // instantiates only if params are comaptible
    bsg_counter_up_down #(  .max_val_p   (max_val_p)
                          , .init_val_p  (init_val_p)
                          , .max_step_p (max_step_p)
                          , .ptr_width_lp()
                         )  DUT
                         (  .clk_i  (clk)
                          , .reset_i(reset)
                          , .up_i   (test_input_up)
                          , .down_i (test_input_down)
                          , .count_o(test_output)
                         );


endmodule
