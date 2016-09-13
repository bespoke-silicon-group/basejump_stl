`define WIDTH_P    ?
`define PERIOD     10 

module test_bsg;

  // Enable VPD file dump
  initial
    begin
      $vcdpluson;
      $vcdplusmemon;
    end

  longint ticks = 0;
  longint t1 = 0;
  longint t2 = 0;

  logic                 clock_in;
  logic                 clock_out;
  logic                 reset;
  logic [`WIDTH_P-1:0]  value;

  bsg_nonsynth_clock_gen #(`PERIOD) clk_gen (clock_in);

  bsg_counter_clock_downsample #(.width_p(`WIDTH_P)) DUT
    (.clk_i(clock_in)
    ,.reset_i(reset)
    ,.val_i(value)
    ,.clk_r_o(clock_out)
    );

  initial
    begin
      $display("                                                           ");
      $display("***********************************************************");
      $display("*                                                         *");
      $display("*                  SIMULATION BEGIN                       *");
      $display("*                                                         *");
      $display("***********************************************************");
      $display("                                                           ");

      value = `WIDTH_P'd0;
      reset = 1'b0;

      @(negedge clock_in);
      reset = 1'b1;
      @(negedge clock_in);
      reset = 1'b0;

      // Check each overflow value for the downsampler
      for (integer i = 0; i < 2**`WIDTH_P; i++)
        begin
            // set the overflow value
            value = i;

            // Measure the output clock period
            @(posedge clock_out);
            t1 = ticks;
            @(posedge clock_out);
            t2 = ticks;

            // Assert the expected period
            assert(t2-t1 == 2*`PERIOD*(i+1))
              $display("Passed: val=%d -- per=%-d", value, t2-t1);
            else
              $error("Failed: val=%-d -- per=%-d -- expected per=%-d", value, t2-t1, 2*`PERIOD*(i+1));
        end

      $display("                                                           ");
      $display("***********************************************************");
      $display("*                                                         *");
      $display("*                 SIMULATION FINISHED                     *");
      $display("*                                                         *");
      $display("***********************************************************");
      $display("                                                           ");
      $finish;
    end

  always #1 ticks = ticks + 1;

endmodule
